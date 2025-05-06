require "http"

class Check
  def self.get_all
    DB[
      <<-SQL
        SELECT
          monitors.id,
          monitors.url,
          monitors.determine,
          monitors.completed_at,
          COUNT(determinations.id) as run_count,
          MAX(determinations.created_at) as last_run_at
        FROM monitors
        LEFT JOIN determinations ON monitors.id = determinations.monitor_id
        GROUP BY 1, 2, 3, 4
        ORDER BY 4 DESC NULLS FIRST
      SQL
    ]
      .all
  end

  def self.determine(monitor)
    chat = RubyLLM.chat

    url = "https://r.jina.ai/" + monitor[:url]
    screenshot_url_res = HTTP.headers("x-respond-with" => "screenshot").get(url)
    screenshot_url = screenshot_url_res.body.to_s.strip
    puts(screenshot_url)
    screenshot_data = HTTP.get(screenshot_url).body.to_s

    response = chat.ask(
      "Given the following screenshot of a webpage, determine #{monitor[:determine]}. Keep your reasoning brief. The very last thing you should output is your 'Determination: true' or 'Determination: false', with that exact formatting.",
      with: {
        image: screenshot_url
      }
    )

    puts("\n\n\n")
    pp(response)

    outcome_word = response.content.strip.split.last
    outcome = begin
      case outcome_word
      when /true/i
        true
      when /false/i
        false
      else
        puts("Unknown outcome: '#{outcome_word}'")
        false
      end
    end

    [outcome, screenshot_data, response]
  end

  def self.run!(monitor)
    outcome, screenshot_data, response = determine(monitor)

    DB[:determinations].insert(
      monitor_id: monitor[:id],
      outcome:,
      screenshot: Sequel::SQL::Blob.new(screenshot_data),
      debug_info: response.to_h.to_json
    )

    if outcome
      PUSHOVER.notify(response.content.strip, url: monitor[:url])
    end
  end
end
