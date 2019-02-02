-- parse .java file to get interface info
--[[
   the final datastruct:
   result["key"] = interface_map
   interface_map[method_name] = interface_data
   interface_data['method']=method
   interface_data['v'] = version
   interface_data['session'] = NeedInSessionType.YES or NeedInSessiontype.NO
   interface_data['sign'] = IgnoreSignType.YES 
   interface_data['params'] = params_map
   params_map[field] = f_type
   ... so many
--]]

apiUtil = {}

local utils = require("utils")

local cjson = require('cjson')

function getInterfaceInfoFromFile(file_name)
   if not file_name then
      return nil
   end
   
   local api_file = io.input(file_name)
   if not api_file then
      print(api_file.." is not exists")
      return nil
   else
      local data = nil
      local api_list = {}
      local index = 1
      local parse_request = false
      repeat
         data = io.read()
         if data then
            if parse_request then
               for v,_ in string.gmatch(data,"%((.-)%s+(.+)%)") do
                  api_list[index-1]['request'] = v
               end
                parse_request = false
            else
               for v in string.gmatch(data,"@ServiceMethod%((.+)%)") do
                  local api_info = {}
                  for str in string.gmatch(v, "([^,]+)") do
                     for k,v in string.gmatch(str,"%s*(.-)%s*=%s*(.+)%s*") do
                        x = string.gsub(k,'"',"")
                        y = string.gsub(v,'"',"")
                        api_info[x] = y
                     end
                  end
                  api_list[index] = api_info
                  index = index + 1
                  parse_request = true
               end
            end
         end
      until not data
      return api_list
   end
end

function parseRequestInfoFromFile(file_name)
   if not file_name then
      return nil
   end
   local f = io.input(file_name)
   if not f then
      print(f.." is not exists")
      return nil
   end
   local data = nil
   local request_map = {}
   repeat
      data = io.read()
      if data then
         for base_class,extends_class in string.gmatch(data,"public%s+class%s+(.-)%s+extends%s+(.-)%s*{") do
            request_map['class'] = base_class
            request_map['extends'] = extends_class
         end
         for f_type,field in string.gmatch(data,"private%s+(.-)%s+(.+);") do
            local logger = string.find(field,"Logger(.+)")
            if not logger then
               local field2 = string.match(field,"([^=]+)")
               if field2 then
                  field2 = string.match(field2,"^%s*(.-)%s*$")
                  request_map[field2] = f_type
               else
                  field = string.match(field,"^%s*(.-)%s*$")
                  request_map[field] = f_type
               end
            end
         end
      end
   until not data
   return request_map
end

function getFilesMapFromDirList(dir_map)
   local files_map = {}
   for k,d in pairs(dir_map) do
      local files = utils.listFiles(d)
      files_map[k] = files
   end
   return files_map
end

--[[
   the api info map datastruct:
   result_map["key"] = all_api_list
   all_api_list[index] = api
   api[method] = method
   api[v] = version
   api[needSession] = NeedSessionInType.YES
   api[ignore] = IgnoreSignType.YES             may nil
--]]
function getAllApiInfoMap()
   local dir_map = {
      weappservice="/home/nnero/project/java/we-parent/we-service/we-api-service/weappservice/src/main/java/me/ddkj/was/api/i/",
      webbsservice="/home/nnero/project/java/we-parent/we-service/we-api-service/webbsservice/src/main/java/me/ddkj/webbsservice/api/i/",
      weCircleService="/home/nnero/project/java/we-parent/we-service/we-api-service/weCircleService/src/main/java/me/ddkj/cirleservice/api/i/",
      wecoreapi="/home/nnero/project/java/we-parent/we-service/we-api-service/wecoreapi/src/main/java/me/ddkj/wecore/api/",
      weuserinfoapi="/home/nnero/project/java/we-parent/we-service/we-api-service/weuserinfoapi/src/main/java/me/ddkj/weuserinfo/api/",
      wesmallservice="/home/nnero/project/java/we-parent/we-service/we-api-service/wesmallservice/src/main/java/me/ddkj/small/api/i/"
   }

   local files_map = getFilesMapFromDirList(dir_map)
   local result_map = {}
   for k,files in pairs(files_map) do
      local all_api_list = {}
      for _,f in pairs(files) do
         local api_list = getInterfaceInfoFromFile(f)
         for _,api in pairs(api_list) do
            table.insert(all_api_list,api)
         end
      end
      result_map[k] = all_api_list
   end
   return result_map
end

--[[
   the request info return datastruct:
   result_map["key"] = request_all_map
   request_all_map[request_name] = request_data
   request_data["class"] = className
   request_data["extends"] = extendsClass
   request_data[field_name] = field_type
   ...
--]]
function getAllRequestInfo()
   local dir_map = {
      weappservice="/home/nnero/project/java/we-parent/we-service/we-api-service/weappservice/src/main/java/me/ddkj/was/api/request/",
      webbsservice="/home/nnero/project/java/we-parent/we-service/we-api-service/webbsservice/src/main/java/me/ddkj/webbsservice/api/request/",
      wecoreapi="/home/nnero/project/java/we-parent/we-service/we-api-service/wecoreapi/src/main/java/me/ddkj/wecore/api/request/",
      weCircleService="/home/nnero/project/java/we-parent/we-service/we-api-service/weCircleService/src/main/java/me/ddkj/cirleservice/api/request/",
      weuserinfoapi="/home/nnero/project/java/we-parent/we-service/we-api-service/weuserinfoapi/src/main/java/me/ddkj/weuserinfo/api/request/",
      wesmallservice="/home/nnero/project/java/we-parent/we-service/we-api-service/wesmallservice/src/main/java/me/ddkj/small/api/request/"
   }
   local files_map = getFilesMapFromDirList(dir_map)
   local result_map = {}
   for k,files in pairs(files_map) do
      local request_all_map = {}
      for _,f in pairs(files) do
         local request_map = parseRequestInfoFromFile(f)
         local request_name = request_map['class']
         request_all_map[request_name] = request_map
      end
      -- extract extends class's fields to base classes
      for name,r_map in pairs(request_all_map) do
         local extends = r_map["extends"]
         local extends_map = request_all_map[extends]
         if extends_map then
            for extends_name,extends_value in pairs(extends_map) do
               if extends_name ~= "class" and extends_name ~= "extends" then
                  r_map[extends_name] = extends_value
               end
            end
         end
      end
      result_map[k] = request_all_map
   end
   return result_map
end

function getInterfaceMap()
   local api_map = getAllApiInfoMap()
   local request_map = getAllRequestInfo()
   local result = {}
   for k,api_list in pairs(api_map) do
      local request_data = request_map[k]
      local interface = {}
      for _,api in pairs(api_list) do
         local method_map = {}
         method_map['method'] = api['method']
         method_map['v'] = api['version']
         local need_session = string.match(api['needInSession'],"%.(%a+)")
         method_map['session'] = need_session
         local ignore_sign = api['ignoreSign']
         if ignore_sin then
            ignore_sign = string.match(api['ignoreSign'],"%.(%a+)")
            method_map['sign'] = ignore_sign
         else
            method_map['sign'] = 'YES'
         end
         local params = request_data[api['request']]
         if params then
            params['extends'] = nil
            params['class'] = nil
            method_map['params'] = params
         end
         interface[api['method']..'_'..api['version']] = method_map
      end
      result[k] = interface
   end
   return result
end

--[[
-- test function
function testWriteInterfaceFile(interface_map)
   local json_str = cjson.encode(interface_map)
   print(json_str)
end

testWriteInterfaceFile(getInterfaceMap())
--]]

function apiUtil.getInterfacesInfo()
   return cjson.encode(getInterfaceMap())
end

function apiUtil.updateInterfaceCache()
   local api_json = apiUtil.getInterfacesInfo()
   local wf = io.open("interface.json","w")
   wf:write(api_json)
   wf:close()
end

function apiUtil.getInterfaceDataFromCache()
   local f = io.open("interface.json","r")
   if not f then
      local api_json = apiUtil.getInterfacesInfo()
      local wf = io.open("interface.json","w")
      wf:write(api_json)
      wf:close()
      return api_json
   else
      local all = f:read("a")
      f:close()
      return all
   end
end



return apiUtil


