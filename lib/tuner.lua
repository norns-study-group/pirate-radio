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
    tick_labels={80,90, 100,110, 120, 140},
    tick_ids={80,90, 100,110, 120, 140}
  }
  tuner.dialer = Slider:new(dial_slider_args)
  table.insert(tuner.components,tuner.dialer)
end


function tuner:redraw()
  -- draw the ui here
  for i=1,#tuner.components,1 do
    tuner.components[i]:redraw()
  end
end
return tuner