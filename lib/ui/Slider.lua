-- todo: add marker_visible property and getters/setters

local Slider = {}

function Slider:new(args)
  local slider = AbstractComponent:new(args)
  setmetatable(Slider, {__index = AbstractComponent})
  setmetatable(slider, Slider)
  local args = args and args or {}
  slider.min = args.min==nil and 0 or args.min
  slider.max = args.max==nil and 100 or args.max
  slider.orientation = args.orientation==nil and 'h' or args.orientation
  slider.tick_length = args.tick_length==nil and 5 or args.tick_length
  slider.tick_labels = args.tick_labels
  slider.tick_ids = args.tick_ids==nil and {20,40,60,80} or args.tick_ids
  slider.tick_position = args.tick_position
  slider.border = args.border and args.border or false
  slider.warp = args.warp==nil and 'lin' or args.warp
  
  -- slider.pointer_loc = o=='h' and slider.x+(slider.width/2)-3 or slider.y+(slider.height/2)-3
  slider.pointer_loc = o=='h' and slider.x+3 or slider.y+3

  function slider:set_pointer_loc(delta)
    local o = self.orientation
    -- set variables according to the slider's orientation (horizontal/vertical)
    local start,size
    if o == 'h' then
      start = self.x
      size = self.width
    else
      start = self.y
      size = self.height
    end

    -- find the new location of the pointer
    local loc = slider.pointer_loc + delta
    -- constrain the pointer to the edges of the slider
    local pointer_min = start + 1
    local pointer_max = o == 'h' and self.x+self.width-5 or self.y+self.height-5
    loc = util.clamp(loc,pointer_min,pointer_max)

    -- set pointer_loc to the new location
    self.pointer_loc = loc      
  end

  function slider:draw_ticks()
    local o = self.orientation

    -- set variables for the line ticks are attached to according to the slider's orientation (horizontal/vertical)
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
    -- make sure the x/y variables are whole numbers
    x = math.ceil(x)
    y = math.ceil(y)
      
    -- set a size variable according to the slider's orientation (horizontal/vertical)
    local size = o=='h' and self.width or self.height
    
    local stids = slider.tick_ids
    local mark_start, mark_end, mark_text_loc
    for i=1,#stids,1 do      
      -- the distance between each mark
      local mark_delta = (size)/(#stids+1)
      -- the location of each slider tick mark
      local mark_loc = (mark_delta) * i
      
      -- where the mark starts(x/y), ends(x/y), and where to put each mark label(x/y)
      if self.tick_position == "before" then
        mark_start    = o=='h' and {self.x+mark_loc,self.y+self.height/2} or {(self.x+self.width/2),self.y+mark_loc}
        mark_text_loc = o=='h' and {mark_start[1],self.y+self.height/2-1} or {self.x+3,mark_start[2]+2}
      elseif self.tick_position == "after" then
        mark_start    = o=='h' and {self.x+mark_loc,self.y+1} or {self.x+1,self.y+mark_loc}
        mark_text_loc = o=='h' and {mark_start[1],self.y+self.height-2} or {self.x+self.width/2+3,mark_start[2]+2}
      else
        mark_start    = o=='h' and {self.x+mark_loc,self.y+1} or {self.x+1,self.y+mark_loc}
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
      screen.stroke()
      
      if slider.tick_labels then
        -- set the tick text x/y
        mark_text_loc[1] = math.floor(mark_text_loc[1])
        mark_text_loc[2] = math.floor(mark_text_loc[2])
        screen.move(mark_text_loc[1], mark_text_loc[2])
        screen.text_center(slider.tick_labels[i])
      end  
    end

    -- draw a line bisecting the slider
    if o=='h' then
      local line_y = mark_start[2] + (mark_end[2]/2)
      screen.move(x,line_y)
      screen.line_rel(size-2,0)
    else
      local line_x = mark_start[1] + (mark_end[1]/2)
      screen.move(line_x,y)
      screen.line_rel(0,size-1)
    end
    
  end

  function slider:draw_pointer()
    local o = self.orientation
    local level = self.selected and self.selected_level or self.unselected_level
    screen.level(level)
    if self.tick_position == "before" then
      if o == 'h' then
        screen.rect(self.pointer_loc,self.y+self.height/2+1,4,4)
      else
        screen.rect(self.x+self.width/2+1,self.pointer_loc,4,4)
      end
    elseif self.tick_position == "after" then
      if o == 'h' then
        screen.rect(self.pointer_loc,self.y+2,4,4)
      else
        screen.rect(self.x+2,self.pointer_loc,4,4)
      end
    else
      if o == 'h' then
        screen.rect(self.pointer_loc,self.y+(self.height/2)-2,4,4)
      else
        screen.rect(self.x+(self.width/2)-2,self.pointer_loc,4,4)
      end
    end
    screen.stroke()
  end

  function slider:draw_outline()
    -- draw outline
    if slider.border == true then
      local level = self.selected and self.selected_level or self.unselected_level
      screen.level(level)
      screen.move(slider.x,slider.y)
      screen.rect(slider.x,slider.y,slider.width,slider.height)
      screen.stroke()
    end
  end

  function slider:redraw()
    local level = self.selected and self.selected_level or self.unselected_level
    screen.level(level)
    self:draw_ticks()
    self:draw_pointer()
    self:draw_outline()
  end

  return slider
end

return Slider
