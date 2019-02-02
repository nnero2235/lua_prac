
local cjson = require("cjson")
local redis = require("redis_pool")

ngx.req.read_body()
local args = ngx.req.get_uri_args()

local result = {}
if not args or not args['uid'] or args['uid'] == "" then
   result.msg="uid is nil"
   ngx.say(cjson.encode(result))
   return
end

local sessionid = redis.get("user_sessionId_"..args['uid'])

if not sessionid or sessionid == ngx.null then
   local r = math.random()
   local t = os.time()
   sessionid  = ngx.md5(t..r)
   redis.set("user_sessionId_"..sessionid,args['uid'])
   redis.set("user_sessionId_"..args['uid'],sessionid)
   redis.expire("user_sessionId_"..sessionid,7 * 24 * 60 * 60)
   redis.expire("user_sessionId_"..args['uid'],7 * 24 * 60 * 60)
end

result.msg="ok"
result.sessionid = sessionid
result.uid = args['uid']
ngx.say(cjson.encode(result))
