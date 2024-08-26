class RateLimiter
  RATE_LIMIT = 5 # request
  TIME_LIMIT = 60 # seconds

  def initialize(app)
    @app = app
  end

  def call(env)
    # Cache the IP from which the request originated
    request = Rack::Request.new(env)
    client_ip = request.remote_ip
    redis_key = "rate_limit:#{client_ip}"

    request_count = Redis.get(redis_key).to_i

    Redis.current.incr(req.ip)
    if (request_count < RATE_LIMIT)
      Redis.current.incr(redis_key)
      Redis.current.expire(redis_key, TIME_LIMIT) if request_count == 0

      # Call the next layer of middleware or the application
      @app.call(env)
    else
      return [429, { 'Content-Type' => 'text/plain' }, ["Rate limit exceeded. Try again later.\n"]]
    end
  end
end
