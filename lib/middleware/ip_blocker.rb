class IpBlocker
  RATE_LIMIT_COUNT = 3
  TIME_LIMIT = 1.day

  def initialize(app)
    @app = app
    @redis = Redis.new
  end

  def call(env)
    request = Rack::Request.new(env)
    client_ip = request.remote_ip

    redis_key = "rate_limit_count:#{client_ip}"
    count = @redis.get(redis_key).to_i

    if (count > RATE_LIMIT_COUNT)
      blocked_ip_key = "blocked_ips:#{client_ip}"
      @redis.sadd("blocked_ips", client_ip)
      @redis.expire(blocked_ip_key, TIME_LIMIT) if count == 0
    end

    if @redis.sismember("blocked_ips", client_ip)
      return [429, {'Content-Type' => 'text/plain'}, ['Your IP has been blocked temporarily']]
    end
    @app.call(env)
  end
end
