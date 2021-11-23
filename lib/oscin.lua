-------------------------------------------
-- notes

-------------------------------------------

-- norns.script.run("/home/we/dust/code/pirate-radio/pirate-radio.lua")

local oscin={}

oscin.strength=0
oscin.have_info=false
oscin.info={}

function oscin.get_signal_strength()
  return oscin.strength
end

-- get_engine_state asynchronously returns info
-- by utilizing polling and a callback
-- use with engine.getEngineState
function oscin.get_engine_state(fn)
  clock.run(function()
    while true do
      clock.sleep(0.25)
      if oscin.have_info==true then 
        osc.have_info=false
        fn(oscin.info)
        return
      end
    end
  end)
end

function oscin.init()
  osc.event=function(path,args,from)
    if path=="strength" then
      oscin.strength=tonumber(args[1])
    end
    if path=="enginestate" then
      -- TODO: wth happens here?
      print(args)
      oscin.have_info=true
      oscin.info={some="data"}
    end
  end
end

return oscin