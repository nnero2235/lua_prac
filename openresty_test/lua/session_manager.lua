-- manage sessions

local redis = require("redis_pool")

local M = {}

local session_prefix = "weapp_test_session"

function M.getSession(user)
   if not user then
      return nil
   end
   local session = redis.get(session_prefix..user)
   return session
end

function M.generateSession(user)
   local md5_str = ngx.md5(user)
   local ok = redis.set(session_prefix..user,md5_str)
   if not ok then
      ngx.log(ngx.ERR,"gen session fail")
      return nil
   end
   ok = redis.expire(session_prefix..user,7 * 24 * 60 * 60)
   if not ok then
      ngx.log(ngx.ERR,"session expire fail")
      return nil
   end
   return md5_str
end

return M
