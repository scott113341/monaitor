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

screenshot, text = Check.fetch_page(monitor[:url])
screenshot_file = Check.save_temp_file("screenshot", "png", screenshot)
text_file = Check.save_temp_file("body", "txt", text)

async_block = Async do
  10
    .times
    .map { Async { Check.determine(monitor, screenshot_file.path, text_file.path) } }
    .map(&:wait)
end

results = async_block.wait
outcomes = results.map { |outcome, _response| outcome }
responses = results.map { |_outcome, response| response }

pp(responses)
pp(outcomes)
