class Check
  class DeterminationSchema < RubyLLM::Schema
    string(
      :reasoning,
      description: "Some brief plaintext reasoning for your determination"
    )

    boolean(
      :determination,
      description: "Your final determination"
    )
  end

  def self.get_all
    DB[
      <<-SQL
        SELECT
          monitors.id,
          monitors.url,
          monitors.determine,
          monitors.paused,
          COUNT(runs.id) as run_count,
          MAX(runs.created_at) as last_run_at
        FROM monitors
        LEFT JOIN runs ON monitors.id = runs.monitor_id
        GROUP BY 1, 2, 3, 4
        ORDER BY 4, 3
      SQL
    ]
      .all
  end

  def self.determine(monitor)
    screenshot, text = fetch_page(monitor[:url])
    screenshot_file = save_temp_file("screenshot", "png", screenshot)
    text_file = save_temp_file("body", "txt", text)

    chat = RubyLLM.chat.with_schema(DeterminationSchema)

    prompt = "Given this webpage screenshot & body.innerText, determine #{monitor[:determine]}."
    prompt += " " + monitor[:extra_instructions] if monitor[:extra_instructions].present?

    response = chat.ask(
      prompt,
      with: [
        screenshot_file.path,
        text_file.path
      ]
    )
    pp(response)

    outcome = response.content["determination"]
    [outcome, screenshot, response]
  end

  def self.run!(monitor)
    outcome, screenshot, response = determine(monitor)

    DB[:runs].insert(
      monitor_id: monitor[:id],
      outcome:,
      reasoning: response.content["reasoning"],
      screenshot: Sequel::SQL::Blob.new(screenshot),
      debug_info: response.to_h.to_json
    )

    if outcome
      PUSHOVER.notify(response.content["reasoning"], url: monitor[:url])
      # DB[:monitors].where(id: monitor[:id]).update(paused: true)
    end
  end

  def self.with_page(&block)
    playwright_cli_executable_path = "./node_modules/.bin/playwright"

    Playwright.create(playwright_cli_executable_path:) do |playwright|
      playwright.chromium.launch do |browser|
        block.call(browser.new_page)
      end
    end
  end

  def self.fetch_page(url)
    with_page do |page|
      page.goto(url)

      screenshot = page.screenshot(fullPage: true)
      text = page.evaluate("document.body.innerText")

      [screenshot, text]
    end
  end

  def self.save_temp_file(name, extension, data)
    file = Tempfile.new([name, "." + extension])
    file.write(data)
    file.flush
    file.rewind
    file
  end
end
