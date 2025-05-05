require "action_view"
require "active_support/security_utils"
require "sinatra"

class App < Sinatra::Base
  extend(ActiveSupport::SecurityUtils)

  helpers(ActionView::Helpers::DateHelper)

  configure do
    set(:port, ENV.fetch("PORT", 3858))
    set(:bind, "0.0.0.0")
  end

  use(Rack::Auth::Basic) do |u, p|
    secure_compare(u, ENV.fetch("USERNAME", "")) && secure_compare(p, ENV.fetch("PASSWORD", ""))
  end

  get("/") do
    @monitors = Check.get_all
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

  get("/monitors.new") do
    erb(:new_monitor)
  end

  post("/monitors") do
    monitor = DB[:monitors]
      .returning
      .insert(
        determine: params[:determine],
        url: params[:url]
      )
      .first

    Check.run!(monitor)

    redirect("/monitors/#{monitor[:id]}")
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
