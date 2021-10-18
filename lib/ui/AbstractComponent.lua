local AbstractComponent = {}

function AbstractComponent:new(args)
  local ac=setmetatable({},{__index=AbstractComponent})
  local args=args==nil and {} or args
  ac.x=args.x==nil and 20 or args.x
  ac.y=args.y==nil and 20 or args.y 
  ac.width=args.width==nil and 10 or args.width
  ac.height=args.height==nil and 10 or args.height
  -- ac.selected=args.selected==nil and false or args.selected
  ac.selected = args.selected and args.selected or false
  ac.selected_level=args.selected_level==nil and SELECTED_LEVEL_DEFAULT or args.selected_level
  ac.unselected_level=args.unselected_level==nil and UNSELECTED_LEVEL_DEFAULT or args.unselected_level
  
  function ac:get_selected()
    return self.selected
  end

  function ac:set_selected(sel)
    self.selected = sel
  end

  function ac:get_x()
    return self.x
  end

  function ac:set_x(x_loc)
    self.x = x_loc
  end

  function ac:get_y()
    return self.y
  end

  function ac:set_y(y_loc)
    self.y = y_loc
  end

  -- this is an empty function to be overridden by child classes
  function ac:redraw()

  end

  return ac
end

return AbstractComponent