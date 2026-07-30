RSpec.describe(Check) do
  let(:monitor) do
    {
      id: "11111111-2222-3333-4444-555555555555",
      url: "https://example.com/tickets",
      determine: "whether tickets are on sale",
      extra_instructions: nil,
      model: "openai/gpt-5-nano"
    }
  end

  let(:screenshot) { "\x89PNG\r\n\x1A\n binary".b }
  let(:page_text) { "Tickets: SOLD OUT" }

  let(:response) do
    instance_double(
      RubyLLM::Message,
      content: {"determination" => true, "reasoning" => "The page says sold out"},
      to_h: {role: :assistant, content: {"determination" => true}}
    )
  end

  let(:chat) { instance_double(RubyLLM::Chat, total_cost: 0.00009) }

  before do
    # Keep the suite quiet: `determine` logs progress with puts/pp
    allow(described_class).to receive(:puts)
    allow(described_class).to receive(:pp)
  end

  describe(".save_temp_file") do
    it("round-trips binary data and rewinds the file for reading") do
      file = described_class.save_temp_file("screenshot", "png", screenshot)

      expect(file.pos).to(eq(0))
      expect(file.read).to(eq(screenshot))
    end

    it("names the file with the given extension") do
      file = described_class.save_temp_file("body", "txt", page_text)

      expect(File.extname(file.path)).to(eq(".txt"))
      expect(File.basename(file.path)).to(start_with("body"))
    end
  end

  describe(".determine") do
    before do
      allow(described_class).to receive(:fetch_page).and_return([screenshot, page_text])
      allow(RubyLLM).to receive(:chat).and_return(chat)
      allow(chat).to receive(:with_schema).and_return(chat)
      allow(chat).to receive(:ask).and_return(response)
    end

    it("asks the monitor's model via openrouter using the determination schema") do
      described_class.determine(monitor)

      expect(RubyLLM).to(
        have_received(:chat)
          .with(model: "openai/gpt-5-nano", provider: :openrouter, assume_model_exists: true)
      )
      expect(chat).to(have_received(:with_schema).with(Check::DeterminationSchema))
    end

    it("builds the prompt from the monitor's determine text") do
      described_class.determine(monitor)

      expect(chat).to(
        have_received(:ask)
          .with(
            "Given this webpage screenshot & body.innerText, " \
              "determine whether tickets are on sale.",
            anything
          )
      )
    end

    it("appends extra instructions when present") do
      monitor[:extra_instructions] = "Ignore the cookie banner."

      described_class.determine(monitor)

      expect(chat).to(
        have_received(:ask)
          .with(a_string_ending_with("on sale. Ignore the cookie banner."), anything)
      )
    end

    it("does not append blank extra instructions") do
      monitor[:extra_instructions] = "   "

      described_class.determine(monitor)

      expect(chat).to(have_received(:ask).with(a_string_ending_with("on sale."), anything))
    end

    it("attaches the screenshot and page text as files") do
      described_class.determine(monitor)

      expect(chat).to(have_received(:ask)) do |_prompt, with:|
        screenshot_path, text_path = with

        expect(File.extname(screenshot_path)).to(eq(".png"))
        expect(File.binread(screenshot_path)).to(eq(screenshot))
        expect(File.extname(text_path)).to(eq(".txt"))
        expect(File.read(text_path)).to(eq(page_text))
      end
    end

    it("returns the outcome, screenshot, response, and cost") do
      expect(described_class.determine(monitor)).to(eq([true, screenshot, response, 0.00009]))
    end
  end

  describe(".run!") do
    let(:runs) { double("runs dataset") }
    let(:outcome) { true }

    before do
      allow(described_class).to(
        receive(:determine).and_return([outcome, screenshot, response, 0.00009])
      )
      allow(runs).to receive(:insert)

      db = double("DB")
      allow(db).to receive(:[]).with(:runs).and_return(runs)
      stub_const("DB", db)
      stub_const("PUSHOVER", double("PUSHOVER", notify: nil))
    end

    it("records the run against the monitor") do
      described_class.run!(monitor)

      expect(runs).to(
        have_received(:insert)
          .with(
            hash_including(
              monitor_id: monitor[:id],
              outcome: true,
              reasoning: "The page says sold out",
              model: "openai/gpt-5-nano",
              cost: 0.00009
            )
          )
      )
    end

    it("stores the screenshot as a blob and the raw response as debug info") do
      described_class.run!(monitor)

      expect(runs).to(have_received(:insert)) do |row|
        expect(row[:screenshot]).to(be_a(Sequel::SQL::Blob))
        expect(row[:screenshot]).to(eq(screenshot))
        expect(JSON.parse(row[:debug_info])).to(eq(response.to_h.as_json))
      end
    end

    it("notifies pushover with the reasoning when the outcome is true") do
      described_class.run!(monitor)

      expect(PUSHOVER).to(
        have_received(:notify).with("The page says sold out", url: monitor[:url])
      )
    end

    context("when the outcome is false") do
      let(:outcome) { false }

      it("records the run but does not notify") do
        described_class.run!(monitor)

        expect(runs).to(have_received(:insert).with(hash_including(outcome: false)))
        expect(PUSHOVER).not_to(have_received(:notify))
      end
    end
  end
end
