require "active_support/all"
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

App.run! if __FILE__ == $PROGRAM_NAME
