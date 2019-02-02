local template = require("resty.template")
local session = require("session_manager")
local cjson = require("cjson")
local api = require("api_util")

function loginCheck()
   local username = ngx.var.cookie_username
   if not username then
      return false
   end

   local s = session.getSession(username)
   local id = ngx.var.cookie_sessionid
   if not s or not id or s ~= id then
      return false
   end
   return true
end

-- ------------------- business --------------------------
if not loginCheck() then
   ngx.redirect("/render/login.html")
   return
end

ngx.req.read_body()
local params = ngx.req.get_uri_args()
local api_map = cjson.decode(api.getInterfaceDataFromCache())

-- build menu
-- build interface list
local menu_list = {}
local interface_list = {}
for app,api_data in pairs(api_map) do
   local active_app = ""
   if params and params['app'] == app then
      active_app = "active"
   end
   table.insert(menu_list,{
         active= active_app,
         name=app,
         link="/render/main.html?app="..app
   })
   if active_app == "active" then
      for m,data in pairs(api_data) do
         table.insert(interface_list,{
                         name=m,
                         method=data['method'],
                         v=data['v'],
                         session=data['session'],
                         sign=data['sign'],
                         params=data['params'],
         })
      end
      table.sort(interface_list,function(x1,x2) return x1['name'] <= x2['name'] end)
   end
end

return template.render("main.html",{
                          title="Weapp Test",
                          menu_list=menu_list,
                          interface_list=interface_list,
})
