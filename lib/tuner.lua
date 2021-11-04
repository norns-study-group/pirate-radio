-------------------------------------------
-- notes

-------------------------------------------

local tuner = {}

tuner.components = {}

function tuner.init()
  if debug == true then
    tc = tuner.components
  end

  tuner.build_ui()  
end

function tuner.build_ui()
  local dial_slider_args = {
    x=5,
    y=5,
    width=SCREEN_SIZE.x-9,
    height=14,
    orientation='h',
    border=true,
    selected=true,
    tick_position = 'before',
    tick_labels=tuner_labels,
    tick_values=tuner_values
  }
  tuner.dialer = Slider:new(dial_slider_args)
  table.insert(tuner.components,tuner.dialer)
end


function tuner:redraw()
  -- draw the ui here
  for i=1,#tuner.components,1 do
    tuner.components[i]:redraw()
  end
  screen.move(120,40)
  screen.level(math.floor(util.linexp(0,1,2,15.9,oscin.strength)))
  screen.font_size(24)
  -- TODO: replace radio.dial with params
  screen.text_right(string.format("%2.2f",params:get("dial")))
  screen.font_size(8)
end

return tuner