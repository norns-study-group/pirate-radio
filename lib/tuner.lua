-------------------------------------------
-- notes

-------------------------------------------

local tuner = {}

tuner.components = {}

function tuner.init()
  if debug == true then
    tc = tuner.components
  end

  tuner.build_ui()  
end

function tuner.build_ui()
  local dial_slider_args = {
    x=5,
    y=5,
    width=SCREEN_SIZE.x-9,
    height=14,
    orientation='h',
    border=true,
    selected=true,
    tick_position = 'before',
    tick_labels=tuner_labels,
    tick_values=tuner_values
  }
  tuner.dialer = Slider:new(dial_slider_args)
  tuner.dialer.pointer_loc_callback=function(loc)
    loc=util.linlin(dial_slider_args.x,dial_slider_args.x+dial_slider_args.width,70,150,loc)
    print("tuner: setting dial to "..loc)
    engine.dial(loc)
  end
  table.insert(tuner.components,tuner.dialer)
end


function tuner:redraw()
  -- draw the ui here
  for i=1,#tuner.components,1 do
    tuner.components[i]:redraw()
  end
end

return tuner