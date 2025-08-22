require "active_support/all"
require "dotenv/load"
require "ruby_llm"
require "rushover"
require "sequel"
require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.push_dir(File.join(__dir__, "app"))
loader.setup

DB = Sequel.connect(ENV.fetch("DATABASE_URL"), search_path: "public_7")
DB.extension(:pg_json)

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
          next if monitor[:paused]
          next if (monitor[:last_run_at] || Time.at(0)) > Time.now.utc - 8.hours

          sleep(1.minute + rand(10.seconds))
          puts("Running #{monitor[:id]}")
          Check.run!(monitor)
        end

      rescue StandardError => e
        puts("Error: #{e.message}")
      end

      sleep(1.minute)
    end
  end

  App.run!
end
