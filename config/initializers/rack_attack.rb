class Rack::Attack
  throttle("req/ip", limit: 30, period: 10) { |req| req.ip }
end
