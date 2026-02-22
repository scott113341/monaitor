require "active_support/security_utils"

module Helpers
  include ActiveSupport::SecurityUtils

  def protected!
    auth = Rack::Auth::Basic::Request.new(request.env)
    unless auth.provided? &&
        auth.basic? &&
        secure_compare(auth.credentials[0], ENV.fetch("USERNAME", "")) &&
        secure_compare(auth.credentials[1], ENV.fetch("PASSWORD", ""))
      response["WWW-Authenticate"] = "Basic realm=\"Restricted Area\""
      halt(401, "Not authorized\n")
    end
  end

  def format_cost(cost)
    return "Unknown cost" if cost.nil?
    return "Free" if cost == 0
    "$#{cost.round(5)}"
  end
end
