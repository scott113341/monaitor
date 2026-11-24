require "active_support/all"
require "dotenv/load"
require "playwright"
require "ruby_llm"
require "schematist"
require "rushover"
require "sequel"
require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.push_dir(File.join(__dir__, "app"))
loader.setup

DB = Sequel.connect(ENV.fetch("DATABASE_URL"), search_path: "public_10")
DB.extension(:pg_json, :pg_interval)

PUSHOVER_API_TOKEN = ENV.fetch("PUSHOVER_API_TOKEN")
PUSHOVER_USER_KEY = ENV.fetch("PUSHOVER_USER_KEY")
PUSHOVER = Rushover::User.new(PUSHOVER_USER_KEY, Rushover::Client.new(PUSHOVER_API_TOKEN))

RubyLLM.configure do |config|
  config.openrouter_api_key = ENV.fetch("OPENROUTER_API_KEY")
  config.default_model = "mistralai/mistral-small-3.1-24b-instruct:free"
  # config.default_model = "openai/gpt-5-nano"
end

if __FILE__ == $PROGRAM_NAME
  Scheduler.start

  App.run!
end
