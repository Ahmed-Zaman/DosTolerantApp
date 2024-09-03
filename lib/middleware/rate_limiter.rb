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
    rate_limit_key = "rate_limit:#{client_ip}"

    request_count = Redis.get(rate_limit_key).to_i

    if (request_count < RATE_LIMIT)
      Redis.current.incr(rate_limit_key)
      Redis.current.expire(rate_limit_key, TIME_LIMIT) if request_count == 0

      rate_limit_count = "rate_limit_count:#{client_ip}"
      Redis.current.incr(rate_limit_count)
      Redis.current.expire(rate_limit_key, TIME_LIMIT * TIME_LIMIT) if request_count == 0
      # Call the next layer of middleware or the application
      @app.call(env)
    else
      return [429, { 'Content-Type' => 'text/plain' }, ["Rate limit exceeded. Try again later.\n"]]
    end
  end
end
