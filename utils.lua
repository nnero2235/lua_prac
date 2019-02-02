-- common utils

utils = {}

-- string trim
function utils.trim(str)
   if not str or type(str) ~= 'string' then
      error("str is nil or str is not string.")
   end
   return string.match(str,"^%s*(.-)%s*$")
end

-- split str with seq "c"
-- not support lua regex or common regex
function utils.split(str,c)
   if not str or type(str) ~= 'string' then
      error("split error: str is nil or not string")
   end
   if not c or type(c) ~= 'string' then
      error("split error: seq c is nil or not string ")
   end
   local s_list = {}
   string.gsub(str,"[^"..c.."]+",function (s) table.insert(s_list,s) end)
   return s_list
end

-- list files in a certain directory
function utils.listFiles(dir)
   if not dir or type(dir) ~= 'string' then
      error("dir is nil or not string.")
   end
   local result = io.popen("ls -l "..dir,"r")
   local files = {}
   if result then
      for v in result:lines() do
         local f = string.match(v,"^-.+")
         if f then
            local str_list = utils.split(f," ")
            table.insert(files,dir..str_list[#str_list])
         end
      end
      io.close(result)
   end
   return files
end

function utils.parseFormData(str)
   if not str or type(str) ~= 'string' then
      return nil
   end
   local data = utils.split(str,"&")
   local result = {}
   for _,s in ipairs(data) do
      local k,v = string.match(s,"(.-)=(.*)")
      result[k] = v
   end
   return result
end

function utils.urlEncode(s)
   if not s then
      return nil
   end
   s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
   return string.gsub(s, " ", "+")
end
 
function utils.urlDecode(s)
   if not s then
      return nil
   end
   s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
   return s
end

function utils.printTable(root)
   local cache = {  [root] = "." }
   local function _dump(t,space,name)
      local temp = {}
      for k,v in pairs(t) do
         local key = tostring(k)
         if cache[v] then
            table.insert(temp,"+" .. key .. " {" .. cache[v].."}")
         elseif type(v) == "table" then
            local new_key = name .. "." .. key
            cache[v] = new_key
            table.insert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. string.rep(" ",#key),new_key))
         else
            table.insert(temp,"+" .. key .. " [" .. tostring(v).."]")
         end
      end
      return table.concat(temp,"\n"..space)
   end
   print(_dump(root, "",""))
end

--[[
-- test utils

function print_list(list)
   if not list then
      error("list is nil")
   end
   for i,v in ipairs(list) do
      print("index:"..i.." value:"..v)
   end
end

function testTrim()
   local s = "nnero"
   print(utils.trim(s).."!")
   s = " nnero "
   print(utils.trim(s).."!")
   s = "    nnero"
   print(utils.trim(s).."!")
   s ="nnero       "
   print(utils.trim(s).."!")
   s = " nn    er o  "
   print(utils.trim(s).."!")
   s = "   "
   print(utils.trim(s).."!")
end

function testSplit()
   local s = "nnero like me"
   local list = utils.split(s," ")
   s = ",nnero,fuck, asd nnero,12 907127&%$#$# ,,"
   list = utils.split(s,",")
   print_list(list)
end

function testListFiles()
   local dir = "/home/nnero/project/java/we-parent/we-service/we-api-service/weappservice/src/main/java/me/ddkj/was/api/i/"
   local list = utils.listFiles(dir)
   print_list(list)
   dir = "/home/nnero/working/"
   list = utils.listFiles(dir)
   print_list(list)
end

function testParseFormData()
   local s = "a=1&b=3&c=112jkjks"
   local result = utils.parseFormData(s)
   print(result['a']..result['b']..result['c'])
   s = "a=1&"
   result = utils.parseFormData(s)
   print(result['a'])
   s = "a=1&b="
   result = utils.parseFormData(s)
   print(result['a']..(result['b'] or 'nil'))
end

--testTrim()
--testSplit()
--testListFiles()
testParseFormData()
--]]

return utils
