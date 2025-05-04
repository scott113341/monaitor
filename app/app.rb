require "action_view"
require "sinatra"

class App < Sinatra::Base
  helpers(ActionView::Helpers::DateHelper)

  configure do
    set(:port, ENV.fetch("PORT", 3858))
    set(:bind, "0.0.0.0")
  end

  get("/") do
    @monitors = DB[
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

    @determinations = DB[
      <<-SQL,
        SELECT *
        FROM determinations
        WHERE monitor_id = ?
        ORDER BY created_at DESC
      SQL
      params[:id]
    ]
      .all

    erb(:monitor)
  end

  post("/monitors/:id/run") do
    monitor = DB[
      <<-SQL,
        SELECT *
        FROM monitors
        WHERE monitors.id = ?
      SQL
      params[:id]
    ]
      .first

    Check.run!(monitor)

    redirect("/monitors/#{params[:id]}")
  end

  get("/determinations/:id/screenshot") do
    determination = DB[
      <<-SQL,
        SELECT screenshot
        FROM determinations
        WHERE id = ?
      SQL
      params[:id]
    ]
      .first

    content_type("image/png")
    determination[:screenshot]
  end
end
