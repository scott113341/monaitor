require_relative "../main"

monitor = DB[:monitors].where(id: "c2d12ead-72fe-4eff-b7f8-6726f1ff51bc").first

pp(monitor)

outcomes = []
responses = []

10.times do
  check = Check.determine(monitor)
  outcomes.push(check[0])
  responses.push(check[2])
  sleep(21.seconds)
end

pp(responses)
pp(outcomes)
