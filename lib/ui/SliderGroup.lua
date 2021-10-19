-- notes
--  the component assumes the width/height of each child slider is the same
--  todo: figure out why this line needs a magic number `10`:
        -- `screen.rect(sg.x,sg.y,sg.width+10,sg.height)`
local SliderGroup = {}

function SliderGroup:new(args)
  local sg = AbstractComponent:new(args)
  setmetatable(SliderGroup, {__index = AbstractComponent})
  setmetatable(sg, SliderGroup)
  local args = args and args or {}
  sg.slider_args_start = args.slider_args_start
  sg.slider_args_middle = args.slider_args_middle
  sg.num_middle_args = args.num_middle_args == nil and 2 or args.num_middle_args 
  sg.slider_args_finish = args.slider_args_finish
  sg.orientation = args.orientation==nil and 'v' or args.orientation
  sg.show_values = false
  sg.border = args.border and args.border or false
  sg.margin = args.margin and args.margin or 2
  
  sg.sliders = {}

  local slider = {}
  
  function sg:init()
    if sg.slider_args_start then
      slider = Slider:new(sg.slider_args_start)
      table.insert(sg.sliders,slider)
    end
    for i=1,sg.num_middle_args,1 do
      local args = {}
      args = fn.deep_copy(sg.slider_args_middle)
      if i>1 then
        local last_slider = slider
        args.x = sg.slider_args_middle.width and last_slider.x + sg.slider_args_middle.width + sg.margin
      end
      slider = Slider:new(args)
      table.insert(sg.sliders,slider)
    end
    if sg.slider_args_finish then
      local last_slider = slider
      sg.slider_args_finish.x = sg.slider_args_finish.width and last_slider.x + last_slider.width + sg.margin
      slider = Slider:new(sg.slider_args_finish)
      table.insert(sg.sliders,slider)
    end

    if sg.orientation == 'v' then
      sg.height = sg.sliders[1].height+2
    else
      sg.width = sg.sliders[1].width+2
    end

    for i=1,#sg.sliders,1 do
      if sg.orientation == 'v' then
        sg.width = sg.width + sg.sliders[i].width
      else
        sg.height = sg.height + sg.sliders[i].height
      end
    end
    sg.height = sg.height + 3
  end
  
  function sg:get_num_sliders()
    return #self.sliders
  end

  function sg:select(selected)
    if selection == 'all' then
      for i=1,#self.sliders,1 do
        self.sliders[i].selected = true
      end
    elseif selected == 'none' then 
      for i=1,#self.sliders,1 do
        self.sliders[i].selected = false
      end
    else
      self.sliders[selected].selected = true
    end
  end

  function sg:draw_outline()
    -- draw outline
    if sg.border == true then
      local level = self.selected and self.selected_level or self.unselected_level
      
      screen.level(level)
      screen.move(sg.x,sg.y)
      screen.rect(sg.x,sg.y,sg.width+10,sg.height)
      screen.stroke()

    end
  end

  function sg:redraw()
    self:draw_outline()
  end

  return sg
end

return SliderGroup
