require "active_support/all"
require "dotenv/load"
require "ruby_llm"
require "rushover"
require "sequel"
require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.push_dir(File.join(__dir__, "app"))
loader.setup

DB = Sequel.connect(ENV.fetch("DATABASE_URL"))
DB.extension(:pg_json)
DB.execute("SET search_path TO #{ENV.fetch("DATABASE_SEARCH_PATH")}")

PUSHOVER_API_TOKEN = ENV.fetch("PUSHOVER_API_TOKEN")
PUSHOVER_USER_KEY = ENV.fetch("PUSHOVER_USER_KEY")
PUSHOVER = Rushover::User.new(PUSHOVER_USER_KEY, Rushover::Client.new(PUSHOVER_API_TOKEN))

RubyLLM.configure do |config|
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY")
  config.default_model = "gpt-4.1-nano"
end

if __FILE__ == $PROGRAM_NAME
  Thread.new do
    loop do
      begin
        Check.get_all.each do |monitor|
          next if monitor[:completed_at].present?
          next if monitor[:last_run_at] > Time.now.utc - 8.hours
          puts("Running #{monitor[:id]}")
          Check.run!(monitor)
        end

        sleep(1.minute + rand(10.seconds))
      rescue StandardError => e
        puts("Error: #{e.message}")
      end
    end
  end

  App.run!
end
