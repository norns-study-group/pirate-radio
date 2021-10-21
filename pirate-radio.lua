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
  debug=true
  -- set sensitivity of the encoders
  norns.enc.sens(1,6)
  norns.enc.sens(2,6)
  norns.enc.sens(3,1) -- needs some sensitivity for the tuner

  pages=UI.Pages.new(1,NUM_PAGES)

  parameters.add_params()
  tuner.init()
  eq.init()
  weather.init()
  sync.init()
  sync:download()
  redraw_timer_init()

  initializing=false
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
function redraw_timer_init()
  redrawtimer=metro.init(function()
    local menu_status=norns.menu.status()
    if menu_status==false and initializing==false and screen_dirty==true then
      pirate_radio_pages.update_pages()
      screen_dirty=false

    end
  end,SCREEN_FRAMERATE,-1)
  redrawtimer:start()
end

function cleanup ()
  -- redrawtimer.free_all()
  util.os_capture(_path.code.."pirate-radio/supercollider/classes/stopogg.sh &")
  -- add more cleanup code
end

