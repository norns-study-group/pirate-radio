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
--
--
--  todos: 
--    implement screen_dirty for redrawing components
------------------------------



include "lib/includes"

------------------------------
-- init
------------------------------
function init()

  -- set sensitivity of the encoders
  norns.enc.sens(1,6)
  norns.enc.sens(2,6)
  norns.enc.sens(3,6)

  pages = UI.Pages.new(1, NUM_PAGES)
    
  parameters.add_params()
  radio.init()
  redraw_timer_init()
  
  initializing = false
end

--------------------------
-- encoders and keys
--------------------------
function enc(n, delta)
  encoders_and_keys.enc(n, delta)
end

function key(n,z)
  encoders_and_keys.key(n, z)
end

--------------------------
-- redraw 
--------------------------
function redraw_timer_init()
  redrawtimer = metro.init(function() 
    local menu_status = norns.menu.status()
    if menu_status == false and initializing == false then
      pirate_radio_pages.update_pages()
    end
  end, SCREEN_FRAMERATE, -1)
  redrawtimer:start()  
end


function cleanup ()
  redrawtimer.free_all()

  -- add more cleanup code
end
