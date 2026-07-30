# Deliberately does NOT require ../main.rb: that connects to Postgres and reads
# a handful of required ENV vars at load time. Specs load the app files they
# need directly, and stub DB/PUSHOVER via `stub_const` where those are used.

require "active_support/all"
require "ruby_llm"
require "ruby_llm/cost"
require "ruby_llm/schema"
require "sequel"
require "tempfile"

require_relative "../app/check"
require_relative "../app/helpers"

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.mock_with(:rspec) { |c| c.verify_partial_doubles = true }
end
