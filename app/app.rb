require "action_view"
require "sinatra"

class App < Sinatra::Base
  configure do
    set(:port, ENV.fetch("PORT", 3858))
    set(:bind, "0.0.0.0")
  end

  helpers(ActionView::Helpers::DateHelper)
  helpers(Helpers)

  get("/") do
    monitors = Check.get_all
    @monitors = monitors.select { |m| !m[:paused] }
    @paused_monitors = monitors.select { |m| m[:paused] }
    erb(:index)
  end

  get("/monitors/:id") do
    @monitor = DB[
      <<-SQL,
        SELECT *
        FROM monitors
        WHERE monitors.id = ?
      SQL
      params[:id]
    ]
      .first

    runs = DB[
      <<-SQL,
        SELECT id, created_at, debug_info, outcome, reasoning, model, cost
        FROM runs
        WHERE monitor_id = ?
        ORDER BY created_at DESC
        LIMIT 21
      SQL
      params[:id]
    ]
      .all

    @has_more = runs.length > 20
    @runs = runs.first(20)

    erb(:monitor)
  end

  get("/monitors/:id/runs") do
    offset = (params[:offset] || 0).to_i
    limit = 20

    runs = DB[
      <<-SQL,
        SELECT id, created_at, debug_info, outcome, reasoning, model, cost
        FROM runs
        WHERE monitor_id = ?
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
      SQL
      params[:id], limit + 1, offset
    ].all

    @has_more = runs.length > limit
    @runs_page = runs.first(limit)
    @monitor_id = params[:id]
    @next_offset = offset + @runs_page.length

    case params[:format]
    when "mobile"
      erb(:_run_cards, layout: false)
    else
      erb(:_run_rows, layout: false)
    end
  end

  get("/monitors.new") do
    protected!
    erb(:new_monitor)
  end

  get("/monitors/:id/edit") do
    protected!
    @monitor = DB[:monitors].where(id: params[:id]).first
    erb(:edit_monitor)
  end

  post("/monitors/:id") do
    protected!

    model = params[:model] == "other" ? params[:custom_model] : params[:model]

    DB[:monitors].where(id: params[:id]).update(
      url: params[:url],
      determine: params[:determine].sub(/\.\s*\Z/, ""),
      extra_instructions: params[:extra_instructions]&.strip.presence,
      run_interval: params[:run_interval],
      model:
    )

    redirect("/monitors/#{params[:id]}")
  end

  post("/monitors") do
    protected!

    model = params[:model] == "other" ? params[:custom_model] : params[:model]

    monitor = DB[:monitors]
      .returning
      .insert(
        url: params[:url],
        determine: params[:determine].sub(/\.\s*\Z/, ""),
        extra_instructions: params[:extra_instructions]&.strip.presence,
        run_interval: params[:run_interval],
        model:
      )
      .first

    Check.run!(monitor)

    redirect("/monitors/#{monitor[:id]}")
  end

  post("/monitors/:id/action") do
    protected!

    case params[:action]
    when "run"
      monitor = DB[:monitors].where(id: params[:id]).first
      Check.run!(monitor)
    when "pause"
      DB[:monitors].where(id: params[:id]).update(paused: true)
    when "resume"
      DB[:monitors].where(id: params[:id]).update(paused: false)
    end

    redirect("/monitors/#{params[:id]}")
  end

  get("/runs/:id/screenshot") do
    content_type("image/png")
    DB[:runs].where(id: params[:id]).first[:screenshot]
  end
end
