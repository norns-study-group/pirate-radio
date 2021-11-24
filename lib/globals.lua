-- global functions and variables 

-------------------------------------------
-- global functions
-------------------------------------------

-- here's a version that handles recursive tables here:
--  http://lua-users.org/wiki/CopyTable
fn = {}
function fn.deep_copy(orig, copies)
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      if copies[orig] then
          copy = copies[orig]
      else
          copy = {}
          copies[orig] = copy
          for orig_key, orig_value in next, orig, nil do
              copy[fn.deep_copy(orig_key, copies)] = fn.deep_copy(orig_value, copies)
          end
          setmetatable(copy, fn.deep_copy(getmetatable(orig), copies))
      end
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end

function fn.set_screen_dirty()
    clock.sleep(0.1)
    screen_dirty = true
end

function fn.load_json(fname)
  if not util.file_exists(fname) then
    do return end
  end
  local f = assert(io.open(fname,"rb"))
  local content = f:read("*all")
  f:close()
  if content==nil then 
    do return end 
  end
  return json.decode(content)
end

function fn.index_of(arr,num)
  for i,v in ipairs(arr) do 
    if num==v then 
      do return i end 
    end
  end
end

function fn.path_split(filename)
  local pathname,fname,ext=string.match(filename,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  return pathname,fname,ext
end

function fn.audio_metadata(fname)
  -- meta data is of the form
  -- TAG:encoder=Lavc58.54.100 libvorbis
  -- TAG:metaband='0'
  -- TAG:metaartist=''
  -- TAG:metaotherinfo=''
  -- TAG:metafile='DNITA_vocal_phrase_all_the_time_dry_80_Ab_bpm80.wav'
  -- TAG:metabpm='112.96'

  local metadata={}
  local tempfile="/tmp/tmp"..math.random()
  local output=util.os_capture("ffprobe -i "..fname.." -show_streams -v quiet > "..tempfile)
  local lines = {}
  for line in io.lines(tempfile) do 
      lines[#lines + 1] = line
  end
  util.os_capture("rm "..tempfile)
  for i,line in ipairs(lines) do 
      local prefix="TAG:"
      if line:find(prefix,1,#prefix) then 
          local kv=string.sub(line,#prefix+1)
          local equalsloc=string.find(kv,"=")
          k=string.sub(kv,1,equalsloc-1)
          local v=""
          local quoteloc=string.find(string.sub(kv,equalsloc),"'")
          if quoteloc~=nil then 
              v=string.sub(kv,equalsloc+2)
              quoteloc=string.find(v,"'")
              v=string.sub(v,1,quoteloc-1)
          else
              v=string.sub(kv,equalsloc+1)
          end
          metadata[string.lower(k)]=v
      end
  end
  return metadata
end

function fn.shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

-- convert seconds into hour:minute:seconds.milliseconds
function fn.ffmpeg_seconds_format(seconds)
  local hours=0
  local minutes=0
  while seconds > 60 do
	minutes = minutes + 1
	seconds = seconds - 60
  end
  while minutes > 60 do 
	  minutes = minutes - 60
	  hours = hours +1
  end
  seconds=math.floor(seconds*10)/10
  return string.format("%02d:%02d:%04.1f",hours,minutes,seconds)
end

-------------------------------------------
-- global variables
-------------------------------------------
SCREEN_FRAMERATE = 1/7
SCREEN_SIZE = {x=127,y=64}
NUM_PAGES = 5

menu_status = false
initializing = true
screen_dirty = true
alt_key_active = false

SETTINGS_PATH = norns.state.data .. "pirate_radio_settings.txt"
-------------------------------------------
-- ui component global variables
-------------------------------------------
SELECTED_LEVEL_DEFAULT    = 15
UNSELECTED_LEVEL_DEFAULT  = 8
TUNER_MIN = 88
TUNER_MAX = 108
tuner_values = {90,94,98,102,106}
tuner_labels = {90,94,98,102,106}
eq_labels = {-12,0,12}
eq_values = {-12,0,12}



