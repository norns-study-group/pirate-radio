-------------------------------------------
-- notes

-------------------------------------------

local visualizer = {}

visualizer.version=1 -- TODO: make this a parameter setting instead
function visualizer:redraw()
  if visualizer.version==1 then 
    visualizer.lines()
  end
  -- TODO: other visualizers
end

function visualizer.lines()
  local bands=oscin.eq
  for i,band in pairs(bands) do
    screen.level(15)
    local h=util.linlin(0,1,54,1,band)
    screen.move(i*12+1-6,h)
    screen.line(i*12+10-6,h)
    screen.stroke()
  end
end

return visualizer
