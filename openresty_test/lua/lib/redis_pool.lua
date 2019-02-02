-- redis pool with module 'resty.redis'

local redis = require("resty.redis")

local M = {}

local function doCommand(callback,...)
   local red = redis:new()
   red:set_timeout(1000)
   local ok,err = red:connect("192.168.1.254",6379)
   if not ok then
       ngx.log(ngx.ERR,"redis connect error: "..err.." try auth...")
       return nil
   end
   local count
   count,err = red:get_reused_times()
   if count == 0 then
      ok,err = red:auth("ddkj")
      if not ok then
         ngx.log(ngx.ERR,"redis auth fail:"..err)
         return nil
      end
   end
   local result = callback(red,...)
   -- mean success
   ok,err = red:set_keepalive(10000,100)
   if not ok then
      ngx.log(ngx.ERR,"set_keepalive error:"..err)
   end
   return result
end

function M.set(k,v)
   if not v or not k then
      ngx.log(ngx.ERR,"redis set k is nil or value is nil")
      return
   end
   return doCommand(function(r,k,v) return r:set(k,v) end,k,v)
end

function M.get(k)
   if not k then
      ngx.log(ngx.ERR,"redis get k is nil")
   end
   return doCommand(function(r,k) return r:get(k) end,k)
end

function M.expire(k,time)
   if not k or not time then
      ngx.log(ngx.ERR,"redis expire k or time is nil")
      return
   end
   return doCommand(function(r,k,v) return r:expire(k,time) end,k,time)
end

return M
