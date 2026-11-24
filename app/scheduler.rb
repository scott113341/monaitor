# Runs due monitors on a background thread.
class Scheduler
  def self.start(interval: 1.minute)
    Thread.new do
      loop do
        tick
        sleep(interval)
      end
    end
  end

  def self.tick
    Check.get_all.each do |monitor|
      next unless due?(monitor)

      sleep(1.minute + rand(10.seconds))
      puts("Running #{monitor[:id]}")
      Check.run!(monitor)
    rescue => e
      log_error(e)
    end
  rescue => e
    log_error(e)
  end

  def self.due?(monitor)
    return false if monitor[:paused]

    (monitor[:last_run_at] || Time.at(0)) <= Time.now.utc - monitor[:run_interval]
  end

  def self.log_error(error)
    puts("Error: #{error.message}", error.backtrace)
  end
end
