-- Sliding-window rate limiter, executed atomically on Redis.
-- KEYS[1] = rate limit key (e.g. "ratelimit:purchase:{userId or ip}")
-- ARGV[1] = window size in milliseconds
-- ARGV[2] = max requests allowed in the window
-- ARGV[3] = current timestamp in milliseconds
--
-- Returns 1 if the request is allowed, 0 if it should be rejected.

local key = KEYS[1]
local window = tonumber(ARGV[1])
local limit = tonumber(ARGV[2])
local now = tonumber(ARGV[3])
local windowStart = now - window

-- Drop timestamps outside the current window
redis.call('ZREMRANGEBYSCORE', key, 0, windowStart)

local count = redis.call('ZCARD', key)

if count < limit then
    redis.call('ZADD', key, now, now .. '-' .. math.random())
    redis.call('PEXPIRE', key, window)
    return 1
else
    return 0
end
