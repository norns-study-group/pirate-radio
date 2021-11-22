local Dust2Dust={}

-- load json library
if not string.find(package.cpath,"/home/we/dust/code/dust2dust/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/dust2dust/lib/?.so"
end
local json=require("cjson")

-- string.random return random strings https://gist.github.com/haggen/2fd643ea9a261fea2094
local charset={}
-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i=48,57 do table.insert(charset,string.char(i)) end
for i=65,90 do table.insert(charset,string.char(i)) end
for i=97,122 do table.insert(charset,string.char(i)) end

function string.random(length)
  math.randomseed(os.time())
  if length>0 then
    return string.random(length-1)..charset[math.random(1,#charset)]
  else
    return ""
  end
end

-- os.capture to get output from command
function os.capture(cmd,raw)
  local f=assert(io.popen(cmd,'r'))
  local s=assert(f:read('*a'))
  f:close()
  if raw then return s end
  s=string.gsub(s,'^%s+','')
  s=string.gsub(s,'%s+$','')
  s=string.gsub(s,'[\n\r]+',' ')
  return s
end

function Dust2Dust:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o.port=o.port or 10112
  o.name=o.name or string.random(4)
  o.room=o.room or "dust"
  o:start()
  return o
end

function Dust2Dust:receive(fn)
  -- if needed, you can preserve the old osc.event
  --local old_osc_in=osc.event
  osc.event=function(path,args,from)
    if old_osc_in~=nil then
      old_osc_in(path,args,from)
    end
    if path=="/dust2dust" then
      print("recevied data: "..args[1])
      local d=json.decode(args[1])
      fn(d)
    end
  end
end

function Dust2Dust:send(data)
  local d=json.encode(data)
  print("sending to "..self.port..": "..d)
  osc.send({"localhost",self.port},"/dust2dust",{d})
end

function Dust2Dust:start()
  local pid=os.capture("pidof dust2dust")
  print("pidof "..pid)
  if pid=="" then
    if not util.file_exists("/home/we/dust/code/dust2dust/dust2dust") then
      -- download it
      local cmd="wget https://github.com/schollz/dust2dust/releases/download/releases/dust2dust -O /home/we/dust/code/dust2dust/dust2dust"
      print(cmd)
      os.execute(cmd)
    end
    print("running dust2dust")
    local cmd="chmod +x /home/we/dust/code/dust2dust/dust2dust"
    print(cmd)
    os.execute(cmd)
    cmd="/home/we/dust/code/dust2dust/dust2dust --addr https://dust2dust.norns.online --name "..self.name.." --room "..self.room.." --osc-send localhost:10111 --osc-recv localhost:"..self.port.."&"
    print(cmd)
    os.execute(cmd)
  end
end

function Dust2Dust:stop()
  print("stopping")
  os.execute("pkill -9 -f dust2dust")
end

return Dust2Dust
