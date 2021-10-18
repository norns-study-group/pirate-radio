local Slider = {}

function Slider:new(args)
  local slider = AbstractComponent:new(args)
  setmetatable(Slider, {__index = AbstractComponent})
  setmetatable(slider, Slider)
  local args = args and args or {}
  slider.min = args.min==nil and 0 or args.min
  slider.max = args.max==nil and 100 or args.max
  slider.orientation = args.orientation==nil and 'h' or args.orientation
  slider.tick_labels = args.tick_labels==nil and {20,40,60,80} or args.tick_labels
  slider.warp = args.warp==nil and 'lin' or args.warp
  
  slider.pointer_loc = slider.x+(slider.width/2)-3

  function slider:set_pointer_loc(delta)
    local o = self.orientation
    if o == 'h' then
      local loc = slider.pointer_loc + delta
      loc = util.clamp(loc,self.x+1,self.x+self.width-5)
      self.pointer_loc = loc
    end
  end

  function slider:draw_tick_labels()
    local o = self.orientation

    -- draw a line bisecting the slider
    if o == 'h' then
      screen.move(self.x,self.y+(self.height/4))
      screen.line_rel(self.width,0)
    end

    local stl = slider.tick_labels
    for i=1,#stl,1 do
      if o == 'h' then
        -- find the location of each slider tick mark
        local mark_delta = (self.width)/(#stl+1)
        local mark_loc = (mark_delta) * i

        -- draw the tick mark
        screen.move(self.x+mark_loc,self.y+1)
        screen.line_rel(0,(self.height/4)*2-2)
        screen.stroke()
        screen.move(self.x+mark_loc,self.y+self.height-2)
        screen.text_center(stl[i])
      end
    end
  end

  function slider:draw_pointer()
    local o = self.orientation

    screen.level(15)
    screen.rect(self.pointer_loc,self.y+2,4,4)
    screen.stroke()
  end

  function slider:redraw()
    local level = self.selected and self.selected_level or self.unselected_level
    screen.level(level)
    -- draw outline
    screen.move(slider.x,slider.y)
    screen.rect(slider.x,slider.y,slider.width,slider.height)
    -- draw tick labels
    self:draw_tick_labels()
    self:draw_pointer()
  end

  return slider
end

return Slider
