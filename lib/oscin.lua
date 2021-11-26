-------------------------------------------
-- notes

-------------------------------------------

-- norns.script.run("/home/we/dust/code/pirate-radio/pirate-radio.lua")

local oscin={}

oscin.strength=0
oscin.have_info=false
oscin.info={}
oscin.playing={}
oscin.eq={}
for i=1,10 do
  oscin.eq[i]=0
end

function oscin.get_signal_strength()
  return oscin.strength
end

-- get_engine_state asynchronously returns info
-- by utilizing polling and a callback
-- use with engine.getEngineState
function oscin.get_engine_state(fn)
  engine.getEngineState()
  clock.run(function()
    while true do
      clock.sleep(0.25)
      if oscin.have_info==true then
        oscin.have_info=false
        print(json.encode(oscin.info))
        if fn~=nil then
          fn(oscin.info)
        end
        return
      end
    end
  end)
end

function oscin.init()
  osc.event=function(path,args,from)
    if path=="strength" then
      oscin.strength=tonumber(args[1])
    elseif path=="playing" then
      if marquee~=nil then
        marquee:set_playing_info(tonumber(args[1])+1,args[2])
      end
    elseif path=="spectrum" then
      for i=1,10 do
        if args[i]~=nil then
          oscin.eq[i]=tonumber(args[i])
        end
      end
    elseif path=="enginestate" then
      oscin.info={}
      local key=""
      local state=nil
      for i,v in ipairs(args) do
        if i%2==1 then
          key=v
          if key=="station" then
            if state~=nil then
              table.insert(oscin.info,state)
            end
            state={}
          end
        else
          state[key]=v
        end
      end
      if state~=nil then
        table.insert(oscin.info,state)
      end
      oscin.have_info=true
    end
  end
end

return oscin
