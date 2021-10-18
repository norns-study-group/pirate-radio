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

-------------------------------------------
-- ui component global variables
-------------------------------------------
SELECTED_LEVEL_DEFAULT    = 10
UNSELECTED_LEVEL_DEFAULT  = 3

