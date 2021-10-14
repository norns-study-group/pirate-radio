local AbstractComponent = {}

function AbstractComponent:new(args)
  local ac=setmetatable({},{__index=AbstractComponent})
  local args=args==nil and {} or args
  print("args.width",args.width)
  ac.x=args.x==nil and 20 or args.x
  ac.y=args.y==nil and 20 or args.y
  ac.width=args.width==nil and 10 or args.width
  ac.height=args.height==nil and 10 or args.height
  
  function ac.redraw()
    -- print("abstract component redraw")
  end

  return ac
end

return AbstractComponent