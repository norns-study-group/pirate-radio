function os_capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

function download(folder)
  local files=os_capture("ls "..folder)
  print(files)
  local file_list={}
  for word in files:gmatch("%S+") do
    file_list[word]=true
  end
  print(file_list[1])
  local dl=os_capture("curl https://coffer.norns.online/uploads")
  print(dl)

  local server_list={}
  for w in string.gmatch(dl,'"(.-)"') do
    print(w)
    if w~="uploads" then
      table.insert(server_list,w)
    end
  end
  print(server_list[1])

  local missing_files={}
  for _,w in ipairs(server_list) do
    if file_list[w]==nil then
      table.insert(missing_files,w)
    end
  end
  for _,w in ipairs(missing_files) do
    -- https://coffer.norns.online/01cb0c021c4092454b1795876e990fa3.ogg
    -- TODO: figure right path
    print("curl -o "..folder.."/"..w.." https://coffer.norns.online/"..w)
    os_capture("curl -o "..folder.."/"..w.." https://coffer.norns.online/"..w)
  end
end

function upload(file_name)
  -- curl -F file="@somefile.wav" https://coffer.norns.online/upload
  file_name=os_capture('curl -F file="@'..file_name..'" https://coffer.norns.online/upload')
  print(file_name)
end

download(".")
upload(file_name)
