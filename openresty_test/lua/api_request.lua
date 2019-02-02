local cjson = require("cjson")
local utils = require("utils")
local cutils = require("cutils")

function to_hex(bin_str)
   return ({bin_str:gsub(".", function(c) return string.format("%02X", c:byte(1)) end)})[1]
end

function signH5(args)
   local keys = {}
   for k,_ in pairs(args) do
      table.insert(keys,k)
   end
   table.sort(keys)
   local sign_str =""
   for i,k in ipairs(keys) do
      sign_str = sign_str..args[k]..k
   end
   sign_str = sign_str..ngx.ctx.secerts[args['appKey']]
   ngx.log(ngx.ERR,sign_str)
   local sign = string.upper(ngx.md5(sign_str))
   ngx.log(ngx.ERR,sign)
   return sign
end

function signOrigin(args)
   local keys = {}
   for k,_ in pairs(args) do
      table.insert(keys,k)
   end
   table.sort(keys)
   local sign_str = ngx.ctx.secerts[args['appKey']]
   for i,k in ipairs(keys) do
      sign_str = sign_str..k..args[k]
   end
   sign_str = sign_str..ngx.ctx.secerts[args['appKey']]
   ngx.log(ngx.ERR,sign_str)
   local sign = string.upper(to_hex(ngx.sha1_bin(sign_str)))
   ngx.log(ngx.ERR,sign)
   return sign
end

function sign(args)
   if args["appKey"] == 'we_h5_1.0'
      or args["appKey"] == 'we_js_1.0'
      or args["appKey"] == 'we_small_1.0'
   then
      return signH5(args)
   else
      return signOrigin(args)
   end
end

function checkSession(body)
   local needSession = body['session']
   if needSession == "YES" and body['sessionid'] == "" then
      return "sessionid is nil.please login first"
   end
   return "ok"
end

-- body will be removed
function buildRequestString(body)
   local need_session = body['session']
   local need_sign = body['sign']
   body['session'] = nil
   body['sign'] = nil
   body['fm'] = "json"

   local str = ""
   if need_sign == "YES" then
      local sign_params = {}
      for k,v in pairs(body) do
         local m = string.match(k,"(.+)_sign")
         if m and v == 'on' then
            sign_params[m] = utils.urlDecode(body[m])
         end
      end
      sign_params['method'] = body['method']
      sign_params['appKey'] = body['appKey']
      sign_params['v'] = body['v']
      sign_params['fm'] = body['fm']
      str = "sign="..sign(sign_params).."&"
   end
   
   for k,v in pairs(body) do
      if not string.match(k,"(.+)_sign") then
         str = str..k.."="..v.."&"
      end
   end
   str = string.sub(str,1,#str-1)
   return str
end

-----  business -------------

if not ngx.ctx.secerts then
   ngx.ctx.secerts = {
      ["we_android_1.0"]="7E4C2E0EAADEA98C2F1",
      ["we_android_2.0"]="WEZFFAI123DE78C2X17",
      ["we_ios_1.0"]="C8EB32335B4E8A61C58",
      ["we_iospro_1.0"]="56E61323EA4E816CCA9",
      ["we_ioslove_1.0"]="XXDE61323EA4E8SSSA9",
      ["we_sign_1.0"]="B85C206FD1E2A9B843E91C5180CA5D83",
      ["we_js_1.0"]="SFGKKSL4492SF022MDSK930B8",
      ["we_h5_1.0"]="SGFKKSL2392XF022MDBK9308B",
      ["we_small_1.0"]="8D13AB93BDB4C7F5751D9B4B3F796BFB",
   }
end

ngx.req.read_body()
local post_body = ngx.req.get_body_data()
ngx.log(ngx.ERR,post_body)

local result = {}
local body = utils.parseFormData(post_body)

local r = checkSession(body)
if r ~= "ok" then
   result.msg = r
   ngx.say(cjson.encode(result))
   return
end

local url = "http://192.168.1.254:81/"..body['path'].."/was"
body['path'] = nil
local request_str = buildRequestString(body)

ngx.log(ngx.ERR,"r_str:"..request_str)

local start_time = getTimestampMillis()
local http = require('resty.http')
local httpc = http.new()
local res,err = httpc:request_uri(
   url,
   {
      method="POST",
      headers={
          ["Content-Type"] = "application/x-www-form-urlencoded;charset=utf8"
      },
      body = request_str
   }
)
local cost = getTimestampMillis() - start_time

if res.status ~= 200 then
   result.msg = err
   ngx.say(cjson.encode(result))
   return
end

result.msg = "ok"
result.data = res.body
result.cost = cost.." ms"
local c = string.sub(result.data,1,1)
if c == "<" then
   result.fm = 'xml'
elseif c == "{" then
   result.fm = "json"
else
   result.fm = "nil"
end
ngx.say(cjson.encode(result))
