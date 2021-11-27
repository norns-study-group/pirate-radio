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
    margin=5,
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

  tuner.dialer.pointer_loc_callback=function(loc, from_param)
    loc=util.linlin(
      tuner.dialer.pointer_min,
      tuner.dialer.pointer_max,
      TUNER_MIN,
      TUNER_MAX,
      loc)
    print("tuner: setting dial to "..loc)
    tuner:set_dial_brightness()
    engine.dial(loc)
    if from_param ~= true then
      params:set("tuner",loc)
    end
  end

  function tuner:set_dial_loc(loc, from_param)
    loc=util.linlin(
      TUNER_MIN,
      TUNER_MAX,
      tuner.dialer.pointer_min,
      tuner.dialer.pointer_max,
      loc)

    tuner.dialer:set_pointer_loc(loc, from_param)
  end

  table.insert(tuner.components,tuner.dialer)
end


function tuner:set_dial_brightness()
  local level = math.floor(util.linexp(0,1,2,15.9,oscin.get_signal_strength()))
  tuner.dialer:set_selected_level(level)
  -- print("tuner_brightness",level)
end

function tuner:redraw()
  -- draw the ui here
  for i=1,#tuner.components,1 do
    tuner.components[i]:redraw()
  end
  screen.move(120,40)
  screen.level(math.floor(util.linexp(0,1,2,15.9,oscin.get_signal_strength())))
  screen.font_size(24)
  screen.text_right(string.format("%2.1f",params:get("tuner")))
  screen.font_size(8)
  if current_station_image_list_len~=nil then
    -- animation
    local image_id
    if animation_mode == "ping-pong" then
      image_id = frame_counter%(current_station_image_list_len*2) + 1
      if image_id > current_station_image_list_len then
        image_id = (current_station_image_list_len*2) - image_id + 1
      end
    else
      image_id = frame_counter%current_station_image_list_len+1
    end
    screen.display_png(current_station_image_dir..current_station_image_list[image_id],4,22)

  elseif current_station_image~=nil and current_station_image~="" then
    -- still image
    if util.file_exists(current_station_image) then
      screen.display_png(current_station_image,4,22)
    end
  end
end

return tuner
