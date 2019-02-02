ngx.req.read_body()
local args = ngx.req.get_body_data()

local template = require("resty.template")
local utils = require("utils")
local session = require("session_manager")

if not args then
   return template.render("login.html",{
                             login_title="Welcome to Weapp Test"
   })
else
   local params = utils.parseFormData(args)
   if params['user'] == 'admin' and params['pwd'] == 'admin' then
      local id = session.generateSession(params['user'])
      ngx.header['Set-Cookie'] = {"username=admin;path=/","sessionid="..id..";path=/"}
      return ngx.redirect("/render/main.html?app=weappservice")
   else
      return template.render("login.html",{
                                login_title="Welcome to Weapp Test",
                                message="username or password is wrong!",
                                user=params['user'],
                                pwd=params['pwd']
      })
   end
end
