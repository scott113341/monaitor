RSpec.describe(Scheduler) do
  let(:now) { Time.utc(2026, 11, 24, 12, 0, 0) }

  def monitor(id, paused: false, last_run_at: nil, run_interval: 1.day)
    {id:, paused:, last_run_at:, run_interval:}
  end

  before do
    allow(described_class).to receive(:puts)
    allow(described_class).to receive(:sleep)
  end

  describe ".tick" do
    it "logs and returns when listing monitors loses the database connection" do
      allow(Check).to receive(:get_all)
        .and_raise(Sequel::DatabaseDisconnectError, "PQconsumeInput() server closed the connection unexpectedly")

      expect { described_class.tick(now:) }.not_to raise_error
      expect(described_class).to have_received(:puts)
        .with("Error: PQconsumeInput() server closed the connection unexpectedly", anything)
    end

    it "runs the remaining monitors when one run fails" do
      first = monitor("a")
      second = monitor("b")
      allow(Check).to receive(:get_all).and_return([first, second])
      allow(Check).to receive(:run!).with(first).and_raise("boom")
      allow(Check).to receive(:run!).with(second)

      described_class.tick(now:)

      expect(Check).to have_received(:run!).with(second)
    end

    it "skips paused monitors and monitors that ran within their interval" do
      paused = monitor("paused", paused: true)
      recent = monitor("recent", last_run_at: now - 1.hour)
      due = monitor("due", last_run_at: now - 2.days)
      allow(Check).to receive(:get_all).and_return([paused, recent, due])
      allow(Check).to receive(:run!)

      described_class.tick(now:)

      expect(Check).to have_received(:run!).once.with(due)
    end
  end
end
