---pirate radio
-- <version> @<authors>
-- lines: llllllll.co/t/<lines thread id>
--
-- yar...

------------------------------
-- notes and todos
--
-- notes:
--
-- switch debug == true to false before publishing
--
--  todos:
--    implement screen_dirty for redrawing components
------------------------------

include "lib/includes"

------------------------------
-- init
------------------------------
function init()
  debug=false
  -- set sensitivity of the encoders
  norns.enc.sens(1,6)
  norns.enc.sens(2,6)
  norns.enc.sens(3,1) -- needs some sensitivity for the tuner

  pages=UI.Pages.new(1,NUM_PAGES)

  prereqs.install()
  tuner.init()
  magic_eye.init()
  eq.init()
  oscin.init()
  -- dust2dust needs to be defined after oscin
  dust2dust=dust2dust_:new({room="pirateradio"})
  sync.init()

  radio.init()
  playback.init()
  debouncer_timer_init()

  init_midi_16n()

  parameters.add_params()
  parameters.load_settings()

  params:bang()

  -- define the global marquee for the lower right banner
  marquee=Marquee:new()

  redraw_timer_init()

  initializing = false
end


--------------------------
-- 16n
--------------------------
function init_midi_16n()

  local prev_pos_eq_all_slider = nil

  _16n.init(function(midi_msg)
      local slider_id = _16n.cc_2_slider_id(midi_msg.cc)
      local v = midi_msg.val

      if pages.index == 1 then
        if slider_id == 1 then
          v = util.linlin(_16n.min_v(), _16n.max_v(),
                          tuner.dialer.pointer_min, tuner.dialer.pointer_max,
                          v)
          tuner.dialer:set_pointer_loc(v)
        end
      elseif pages.index == 2 then
        if slider_id <= eq.num_bands then
          v = util.linlin(_16n.min_v(), _16n.max_v(),
                          eq.last_value, eq.first_value,
                          v)
          eq:set_band(v, slider_id)
        elseif slider_id == 16 then
          if prev_pos_eq_all_slider == nil then
            prev_pos_eq_all_slider = v
            return
          end

          local delta = prev_pos_eq_all_slider - v
          prev_pos_eq_all_slider = v
          eq:set_all_bands_rel(delta)
          screen_dirty = true
        end
      end
  end)
end

--------------------------
-- encoders and keys
--------------------------
function enc(n,delta)
  encoders_and_keys.enc(n,delta)
end

function key(n,z)
  encoders_and_keys.key(n,z)
end

--------------------------
-- redraw
--------------------------
local menu_activated = false
function redraw_timer_init()
  redrawtimer=metro.init(function()
    local menu_status=norns.menu.status()
    if menu_status==false and initializing==false then
      pirate_radio_pages.update_pages()
      screen_dirty=false
    elseif menu_status==false and initializing==false and menu_activated == true then
      menu_activated = false
      screen_dirty = true
    elseif menu_status==true and menu_activated == false then
      menu_activated = true
    end
    playback:update_state()
    frame_counter = frame_counter+1
    rel_frame_counter = rel_frame_counter + params:get("playback_rate")
  end,SCREEN_FRAMERATE,-1)
  redrawtimer:start()
end


--------------------------
-- debouncer
-- (and things that run async, like internet stuff,
-- that may fail if there is no connection)
--------------------------
function debouncer_timer_init()
  local inited=false
  debouncetimer=metro.init(function()
    if not inited then
      inited=true
      weather.init()
      sync:download()
      dust2dust:send({message="need-sync"})
      comments.init()
    end
    screen_dirty = true
  end,1,-1)
  debouncetimer:start()
end


function cleanup ()
  -- redrawtimer.free_all()
  magic_eye.cleanup()
  dust2dust:stop()
  norns.system_cmd(_path.code.."pirate-radio/supercollider/classes/stopogg.sh &")
  playback:reroute_audio(false)
  -- add more cleanup code
end
