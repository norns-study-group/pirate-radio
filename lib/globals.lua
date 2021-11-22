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
  if not util.file_exists(filename) then
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
-------------------------------------------
-- global variables
-------------------------------------------
SCREEN_FRAMERATE = 1/15
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



