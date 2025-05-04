require "http"

class Check
  def self.run!(monitor)
    chat = RubyLLM.chat

    url = "https://r.jina.ai/" + monitor[:url]
    screenshot_url_res = HTTP.headers("x-respond-with" => "screenshot").get(url)
    screenshot_url = screenshot_url_res.body.to_s.strip
    puts(screenshot_url)
    screenshot = HTTP.get(screenshot_url)

    response = chat.ask(
      "Given the following screenshot of a webpage, determine #{monitor[:determine]}. Keep your reasoning brief. The very last thing you should output is 'true' or 'false', depending on your determination.",
      with: {
        image: screenshot_url
      }
    )

    pp(response)
    puts("\n\n\n")
    puts(response.content)

    outcome = response.content.strip.split.last.downcase == "true"

    DB[:determinations].insert(
      monitor_id: monitor[:id],
      outcome:,
      screenshot: Sequel::SQL::Blob.new(screenshot.body.to_s),
      debug_info: response.to_h.to_json
    )

    if outcome
      PUSHOVER.notify(response.content.strip, url: monitor[:url])
    end
  end
end
