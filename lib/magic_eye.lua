
local magic_eye = {}


-- ------------------------------------------------------------------------
-- state - clocks

local rot_fps = 14
local rot_clock
local warp_fps = 20
local warp_clock


-- ------------------------------------------------------------------------
-- state

local gons = {}

-- rot
local angle_shift = 0

-- warp
local init_v = 20
local max_v = 25
local warp_contraint_attemps = 3
local warp_slipthrough_percent = 1

function magic_eye.set_ceiling(v)
  max_v = v
end

function magic_eye.set_warp_max_constraint_attemps(v)
  warp_contraint_attemps = v
end

function magic_eye.set_warp_slipthrough_percent(v)
  warp_slipthrough_percent = v
end


-- ------------------------------------------------------------------------
-- static conf

local nb_gons = 5 -- nb of polygons
local nb_points = 14 -- nb of points / polygon
local g_levels = {10, 1, 15, 4, 12, 7, 5, 8} -- levels of each polygon, by index



-- ------------------------------------------------------------------------
-- core helpers

function rnd(x)
  if x == 0 then
    return 0
  end
  if (not x) then
    x = 1
  end
  x = x * 100000
  x = math.random(x) / 100000
  return x
end

function srand(x)
  if not x then
    x = 0
  end
  math.randomseed(x)
end

local function cos(x)
  return math.cos(math.rad(x * 360))
end

local function sin(x)
  return -math.sin(math.rad(x * 360))
end


-- ------------------------------------------------------------------------
-- screen helpers

local curr_line_endpoint_x = nil
local curr_line_endpoint_y = nil

local function invalidate_current_line_endpoints()
  curr_line_endpoint_x = nil
  curr_line_endpoint_y = nil
end

function set_current_line_endpoints(x, y)
  curr_line_endpoint_x = x
  curr_line_endpoint_y = y
end

local function line(x1, y1)
  if curr_line_endpoint_x and curr_line_endpoint_y then
    screen.move(curr_line_endpoint_x, curr_line_endpoint_y)
    screen.line(x1, y1)
    screen.stroke()
  end
  set_current_line_endpoints(x1, y1)
end


-- ------------------------------------------------------------------------
-- init / cleanup

function magic_eye.init()
  for i=1,nb_gons do
    gons[i] = {}
    for p=1,nb_points do
      gons[i][p] = init_v
    end
  end

  rot_clock = clock.run(magic_eye.rot)
  warp_clock = clock.run(magic_eye.warp)
end

function magic_eye.cleanup()
  clock.cancel(rot_clock)
  clock.cancel(warp_clock)
end


-- ------------------------------------------------------------------------
-- clocked fns

function magic_eye.rot()
  local step_s = 1 / rot_fps
  while true do
    clock.sleep(step_s)
    angle_shift = (angle_shift + 1)%100
  end
end

function magic_eye.warp()
  local step_s = 1 / warp_fps
  while true do
    clock.sleep(step_s)
    for i=1,nb_gons do
      for p=1,nb_points do
        -- warp once -> would naturally push outwards
        local sign = (gons[i][p] >= max_v) and -1 or 1
        gons[i][p] = gons[i][p] + sign * rnd(2)

        -- then try to constrain
        local attempts = 0
        while attempts < warp_contraint_attemps
          and (gons[i][p] >= max_v
               -- or gons[i][p] < max_v - 10
        ) do
          -- sign = rnd(2) - 1
          gons[i][p] = gons[i][p] + sign * rnd(math.floor(max_v/2))
          attempts = attempts + 1
        end
        -- final constraint
        if gons[i][p] >= max_v then
          if rnd(100) < (100 - warp_slipthrough_percent) then --let some slip though
            gons[i][p] = max_v + rnd(2) - 1 * rnd(math.floor(max_v/3)) * 2
          end
        end
      end
    end
  end
end

function magic_eye.redraw(x, y)
  for i=1,nb_gons do
    magic_eye.draw_ngon(x, y, gons[i], angle_shift/100, g_levels[i])
  end
end


-- ------------------------------------------------------------------------
-- draw

function magic_eye.draw_ngon(x, y, gon, a, level)
  screen.level(level)
  invalidate_current_line_endpoints()

  local n = #gon
  for i=0,n do
    local angle = i/n + a
    local next_i = i+1
    if i == 0 then
      i = #gon
    end
    if next_i == n+1 then
      next_i = 1
    end
    -- print(i.." - "..next_i)
    line(x + gon[i]*cos(angle), y + gon[next_i]*sin(angle))
  end
end

-- ------------------------------------------------------------------------

return magic_eye
