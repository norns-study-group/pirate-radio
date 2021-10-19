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

  local dial_slider_args = {
    x=5,
    y=5,
    width=SCREEN_SIZE.x-10,
    height=14,
    orientation='h',
    border=true,
    selected=true,
    tick_position = 'before',
    tick_labels={80,90, 100,110, 120, 140},
    tick_ids={80,90, 100,110, 120, 140}
  }
  radio.dialer = Slider:new(dial_slider_args)
  table.insert(radio.components,radio.dialer)

  local eq_left_args = {
    x=8,
    y=23,
    width=22,
    height=30,
    orientation='v',
    border=false,
    selected=false,
    tick_labels={-12,0,12},
    tick_position = 'before',
    tick_ids={-12,0,12}
  }

  local eq_middle_args = {
    x=28,
    y=23,
    width=7,
    height=30,
    orientation='v',
    border=false,
    selected=false,
    tick_position = 'center',
    tick_ids={-12,0,12}
  }

  local eq_right_args = {
    -- x=6,
    y=23,
    width=20,
    height=30,
    orientation='v',
    border=false,
    selected=false,
    tick_labels={-12,0,12},
    tick_position = 'after',
    tick_ids={-12,0,12}
  }

  -- radio.eq_slider = Slider:new(eq_left_args)
  -- table.insert(radio.components,radio.eq_slider)

  -- radio.eq_slider2 = Slider:new(eq_middle_args)
  -- table.insert(radio.components,radio.eq_slider2)
  local slider_group_args={
    x = eq_left_args.x-3,
    y = eq_left_args.y-1,
    slider_args_start=eq_left_args,
    slider_args_middle=eq_middle_args,
    num_middle_args=8,
    slider_args_finish=eq_right_args,
    orientation = 'v',
    selected = false,
    border = true,
    margin = 2
  }
  radio.eq = SliderGroup:new(slider_group_args)
  radio.eq:init()
  for i=1,#radio.eq.sliders,1 do
    table.insert(radio.components,radio.eq.sliders[i])
  end
  table.insert(radio.components,radio.eq)
end


function radio.redraw()
  -- draw the ui here
  for i=1,#radio.components,1 do
    radio.components[i]:redraw()
  end
  screen.update()
end
return radio