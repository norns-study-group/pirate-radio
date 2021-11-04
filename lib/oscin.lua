-------------------------------------------
-- notes

-------------------------------------------

-- norns.script.run("/home/we/dust/code/pirate-radio/pirate-radio.lua")

local oscin={}

oscin.strength=0

function oscin.init()
  osc.event=function(path,args,from)
    if path=="strength" then
      oscin.strength=tonumber(args[1])
    end
  end
end

return oscin