require "async"

require_relative "../main"

# MODEL = "google/gemma-3-27b-it" # 7/10, 3 wrong
# MODEL = "moonshotai/kimi-k2.5" # 8/10 right, 2 bad schema
# MODEL = "openai/gpt-5-nano" # 10/10 right
MODEL = "qwen/qwen3.7-flash"

monitor = {
  determine: "whether the Broomfield location is open",
  extra_instructions: nil,
  url: "https://cosmospizza.com",
  model: MODEL
}

pp(monitor)

async_block = Async do
  10
    .times
    .map { Async { Check.determine(monitor) } }
    .map(&:wait)
end

results = async_block.wait
outcomes = results.map { |outcome, _screenshot, _response| outcome }
responses = results.map { |_outcome, _screenshot, response| response }

pp(responses)
pp(outcomes)
