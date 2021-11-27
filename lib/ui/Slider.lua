-- todo: add marker_visible property and getters/setters

local Slider = {}

function Slider:new(args)
  local slider = AbstractComponent:new(args)
  setmetatable(Slider, {__index = AbstractComponent})
  setmetatable(slider, Slider)
  local args = args and args or {}
  slider.orientation = args.orientation==nil and 'h' or args.orientation
  slider.tick_length = args.tick_length==nil and 5 or args.tick_length
  slider.margin = args.margin==nil and 5 or args.margin
  slider.tick_labels = args.tick_labels
  slider.tick_values = args.tick_values==nil and {20,40,60,80} or args.tick_values
  slider.tick_position = args.tick_position
  slider.border = args.border and args.border or false
  slider.warp = args.warp==nil and 'lin' or args.warp
  slider.outline_level = 6
  slider.pointer_min = slider.orientation=='h' and slider.x + slider.margin or slider.y + slider.margin
  slider.pointer_max = slider.orientation=='h' and slider.x+slider.width-slider.margin or slider.y+slider.height-slider.margin

  slider.pointer_loc = slider.orientation =='h' and slider.x + (slider.width/2) or slider.y + (slider.height/2)

  slider.TICK_LEVEL = 3

  function slider:get_pointer_loc()
    return self.pointer_loc 
  end

  function slider:set_pointer_loc(loc, from_param)
    -- set pointer_loc to the new location
    self.pointer_loc = loc
    -- run callback with location
    if self.pointer_loc_callback~=nil then
      self.pointer_loc_callback(loc, from_param)
    end
    
    clock.run(fn.set_screen_dirty)
  end

  function slider:set_pointer_loc_rel(delta)
    local o = self.orientation

    -- find the new location of the pointer
    local loc = slider.pointer_loc + delta

    -- constrain the pointer to the edges of the slider
    -- set variables according to the slider's orientation (horizontal/vertical)
    loc = util.clamp(loc,slider.pointer_min,slider.pointer_max)
    
    -- set pointer_loc to the new location
    self.pointer_loc = loc
    
    -- run callback with location
    if self.pointer_loc_callback~=nil then
      self.pointer_loc_callback(loc)
    end
  end

  function slider:get_selected()
    return self.selected
  end

  function slider:set_selected(selected)
    self.selected = selected
  end

  function slider:draw_ticks()
    screen.level(slider.TICK_LEVEL)

    local o = self.orientation

    -- set variables where the line ticks are attached to according to the slider's orientation (horizontal/vertical)
    local x,y
    if self.tick_position == "before" then
      x = o=='h' and self.x or self.x+(self.width/2)
      y = o=='h' and self.y+(self.height/2) or self.y
    elseif self.tick_position == "after" then
      x = o=='h' and self.x or self.x+(self.width/4)
      y = o=='h' and self.y or self.y
    else
      x = o=='h' and self.x or self.x+(self.width/2)
      y = o=='h' and self.y+(self.height/2) or self.y
    end
      
    -- set a size variable according to the slider's orientation (horizontal/vertical)
    local size = self.pointer_max - self.pointer_min
    
    local stids = slider.tick_values
    local mark_start, mark_end, mark_text_loc
    
    -- the distance between each mark
    local mark_delta = (size/#stids)

    for i=1,#stids,1 do      
      -- the location of each slider tick mark
      local mark_loc = (mark_delta) * (i) - (mark_delta/2)
      
      -- where the mark starts(x/y), ends(x/y), and where to put each mark label(x/y)
      if self.tick_position == "before" then
        mark_start    = o=='h' and {self.x+self.margin+mark_loc,self.y+(self.height/2)} or {self.x+(self.width/2),self.y+self.margin+mark_loc}
        mark_text_loc = o=='h' and {mark_start[1],self.y+self.height/2-1} or {self.x+3,mark_start[2]+2}
      elseif self.tick_position == "after" then
        mark_start    = o=='h' and {self.x+self.margin+mark_loc,self.y+1} or {self.x+1,self.y+self.margin+mark_loc}
        mark_text_loc = o=='h' and {mark_start[1],self.y+self.height-2} or {self.x+self.width/2+3,mark_start[2]+2}
      else
        mark_start    = o=='h' and {self.x+self.margin+mark_loc,self.y+1} or {self.x+1,self.y+self.margin+mark_loc}
      end
      mark_end = o=='h' and {0,slider.tick_length } or {slider.tick_length,0} 
      -- make sure the marks variables are whole numbers
      mark_start[1] = math.floor(mark_start[1])
      mark_start[2] = math.floor(mark_start[2])
      mark_end[1] = math.floor(mark_end[1])
      mark_end[2] = math.floor(mark_end[2])

      -- draw the tick mark
      screen.move(mark_start[1],mark_start[2])
      screen.line_rel(mark_end[1],mark_end[2])
      
      -- set the tick text x/y
      if slider.tick_labels then
        mark_text_loc[1] = math.floor(mark_text_loc[1])
        mark_text_loc[2] = math.floor(mark_text_loc[2])
        screen.move(mark_text_loc[1], mark_text_loc[2])
        screen.text_center(slider.tick_labels[i])
      end  
    end

    -- draw a line bisecting the slider
    if o=='h' then
      local line_y = mark_start[2] + (mark_end[2]/2)
      screen.move(x+self.margin,line_y)
      screen.line_rel(size,0)
    else
      local line_x = mark_start[1] + (mark_end[1]/2)
      screen.move(line_x,y+self.margin)
      screen.line_rel(0,size)
    end
    screen.stroke()

  end

  function slider:draw_pointer()
    local o = self.orientation
    local level = self.selected and self.selected_level or self.unselected_level
    screen.level(level)
    if self.tick_position == "before" then
      if o == 'h' then
        screen.move(self.pointer_loc,self.y+(self.height/2))
        screen.line_rel(0,self.tick_length)
      else
        screen.move(self.x+(self.width/2),self.pointer_loc)
        screen.line_rel(self.tick_length,0)
      end
    elseif self.tick_position == "after" then
      if o == 'h' then
        screen.move(self.pointer_loc,self.y+1)
        screen.line_rel(0,self.tick_length)
      else
        screen.move(self.x+1,self.pointer_loc)
        screen.line_rel(self.tick_length,0)
      end
    else
      if o == 'h' then
        screen.move(self.pointer_loc,self.y+(self.height/2)-2)
        screen.line_rel(0,self.tick_length)
      else
        screen.move(self.x+(self.width/2)-2,self.pointer_loc)
        screen.line_rel(self.tick_length,0)
      end
    end
    screen.stroke()
  end

  function slider:draw_outline()
    -- draw outline
    if slider.border == true then
      -- local level = self.selected and self.selected_level or self.unselected_level
      screen.level(self.outline_level)
      screen.move(self.x,self.y)
      screen.rect(self.x,self.y,self.width,self.height)
      screen.stroke()
    end
  end

  function slider:redraw()
    self:draw_ticks()
    self:draw_pointer()
    self:draw_outline()
  end

  return slider
end

return Slider
