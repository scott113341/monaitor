require_relative "../main"

monitor = DB[:monitors].where(id: "8cb50a0b-ded5-4056-a9e7-bc6afed7fb2e").first

pp(monitor)

outcomes = []
responses = []

10.times do
  outcome, screenshot, response = Check.determine(monitor)
  outcomes.push(outcome)
  responses.push(response)
end

pp(responses)
pp(outcomes)
