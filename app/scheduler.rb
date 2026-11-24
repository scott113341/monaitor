# Runs due monitors on a background thread.
#
# Each pass is wrapped in its own rescue. When Postgres restarts, the query that
# lists monitors raises Sequel::DatabaseDisconnectError. Sequel drops the dead
# connection from its pool, so the next pass reconnects, but only if the thread
# is still alive to make it.
class Scheduler
  def self.start(interval: 1.minute)
    Thread.new do
      loop do
        tick
        sleep(interval)
      end
    end
  end

  def self.tick(now: Time.now.utc)
    Check.get_all.each do |monitor|
      next unless due?(monitor, now:)

      sleep(1.minute + rand(10.seconds))
      puts("Running #{monitor[:id]}")
      Check.run!(monitor)
    rescue => e
      log_error(e)
    end
  rescue => e
    log_error(e)
  end

  def self.due?(monitor, now: Time.now.utc)
    return false if monitor[:paused]

    (monitor[:last_run_at] || Time.at(0)) <= now - monitor[:run_interval]
  end

  def self.log_error(error)
    puts("Error: #{error.message}", error.backtrace)
  end
end
