local Slider = {}

function Slider:new(args)
  local slider = AbstractComponent:new(args)
  setmetatable(Slider, {__index = AbstractComponent})
  setmetatable(slider, Slider)




  function slider:redraw()
     screen.move(slider.x,slider.y)
     screen.rect(slider.x,slider.y,slider.width,slider.height)
  end



  return slider
end

return Slider
