-------------------------------------------
-- notes

-------------------------------------------

local radio = {}

radio.components = {}

function radio.get_control_label()
  return "pirate radio"
end

function radio.init()
  if debug == true then
    c = radio.components
  end

  radio.build_ui()  
end

function radio.build_ui()
  -- component = AbstractComponent:new({width=10})
  -- table.insert(components,component)

  local slider_args = {
    x=5,
    y=5,
    width=SCREEN_SIZE.x-10,
    height=14,
    selected=false,
    orientation="h",
    tick_labels={80,90, 100,110, 120, 140}
  }
  radio.dialer = Slider:new(slider_args)
  -- slider1:init()
  table.insert(radio.components,radio.dialer)
end


function radio.redraw()
  -- draw the ui here
  for i=1,#radio.components,1 do
    radio.components[i]:redraw()
  end
  screen.update()
end

return radio