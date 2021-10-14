local radio = {}

components = {}
-- local component

function radio.get_control_label()
  return "pirate radio"
end

function radio.init()
  print("init radio")  
  -- component = AbstractComponent:new({width=10})
  -- table.insert(components,component)

  slider1 = Slider:new({width=50})
  table.insert(components,slider1)
  slider2 = Slider:new({width=80,y=40})
  table.insert(components,slider2)
  
end


function radio.redraw()
  -- draw the ui here
  for i=1,#components,1 do
    components[i].redraw()
  end
  screen.update()
end

return radio