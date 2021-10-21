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
  debug = true
  -- set sensitivity of the encoders
  norns.enc.sens(1,6)
  norns.enc.sens(2,6)
  norns.enc.sens(3,1) -- needs some sensitivity for the tuner

  pages = UI.Pages.new(1, NUM_PAGES)
    
  parameters.add_params()
  tuner.init()
  eq.init()
  redraw_timer_init()

  init_midi_16n()

  initializing = false
end

--------------------------
-- 16n
--------------------------
function is_sysex_16n_config_dump(sysex_payload)
  return (sysex_payload[2] == 0x7d and sysex_payload[3] == 0x00 and sysex_payload[4] == 0x00
          and sysex_payload[5] == 0x0f)
end

function parse_sysex_16n_config_dump(sysex_payload)
  local i = 6 + 4 -- offset
  local led_power_on = false
  local led_data_blink = false
  local rot = false
  local min_v = 0
  local max_v = 127
  local usb_ch_list={}
  local trs_ch_list={}
  local usb_cc_list={}
  local trs_cc_list={}

  if sysex_payload[i+0] == 1 then
    led_power_on = true
  end
  if sysex_payload[i+1] == 1 then
    led_data_blink = true
  end
  if sysex_payload[i+2] == 1 then
    rot = true
  end
  if sysex_payload[i+2] == 1 then
    rot = true
  end

  -- NB: these seem to be wrongly reported...
  -- min_v = (sysex_payload[i+5] << 8) + sysex_payload[i+4]
  -- max_v = (sysex_payload[i+7] << 8) + sysex_payload[i+6]

  for fader_i=0, 16-1 do
    local usb_ch = sysex_payload[i+16+fader_i]
    table.insert(usb_ch_list, usb_ch)

    local trs_ch = sysex_payload[i+32+fader_i]
    table.insert(usb_ch_list, trs_ch)

    local trs_cc = sysex_payload[i+48+fader_i]
    table.insert(usb_cc_list, trs_cc)

    local usb_cc = sysex_payload[i+64+fader_i]
    table.insert(trs_cc_list, usb_cc)
  end

  return {
    led_power_on = led_power_on,
    led_data_blink = led_data_blink,
    rot = rot,
    min_v = min_v,
    max_v = max_v,
    usb_ch = usb_ch_list,
    trs_ch = trs_ch_list,
    usb_cc = usb_cc_list,
    trs_cc = trs_cc_list,
  }
end

function init_midi_16n()
  local mididevice={}
  midi_channels={"all"}
  for i=1,16 do
    table.insert(midi_channels,i)
  end
  for _,dev in pairs(midi.devices) do
    if dev.name~=nil and dev.name == "16n" then
      print("detected 16n, lookup of its xonfig via sysex")
      mididevice[dev.name]={
        name=dev.name,
        port=dev.port,
        midi=midi.connect(dev.port),
        active=true,
        conf_16n=nil
      }

      -- retrieve CC list via sysex

      local is_sysex_dump_on = false
      local sysex_payload = {}

      mididevice[dev.name].midi.event=function(data)
        local d=midi.to_msg(data)
        if is_sysex_dump_on then
          for _, b in pairs(data) do
            table.insert(sysex_payload, b)
            if b == 0xf7 then
              is_sysex_dump_on = false
              -- 0x0F - "c0nFig"
              if is_sysex_16n_config_dump(sysex_payload) then
                local conf_16n = parse_sysex_16n_config_dump(sysex_payload)
                tab.print(conf_16n)
                mididevice[dev.name].conf_16n = conf_16n
                print("done retrieving 16n config")
              end
            end
          end
        elseif d.type == 'sysex' then
          is_sysex_dump_on = true
          sysex_payload = {}
          for _, b in pairs(d.raw) do
            table.insert(sysex_payload, b)
          end
        elseif d.type == 'cc' and mididevice[dev.name].conf_16n ~= nil then
          local cc = d.cc
          local slider_id = nil
          for i, slider_cc in pairs(mididevice[dev.name].conf_16n.usb_cc) do
            if slider_cc == cc then
              slider_id = i
            end
          end
          if mididevice[dev.name].conf_16n.rot then
            slider_id = 16 + 1 - slider_id
          end
          -- cc - 32 + 1
          local v = d.val

          if pages.index == 1 then
            if slider_id == 1 then
              v = util.linlin(mididevice[dev.name].conf_16n.min_v, mididevice[dev.name].conf_16n.max_v,
                              tuner.dialer.pointer_min, tuner.dialer.pointer_max,
                              v)
              tuner.dialer:set_pointer_loc(v)
            end
          elseif pages.index == 2 then
            if slider_id <= eq.num_bands then
              v = util.linlin(mididevice[dev.name].conf_16n.min_v, mididevice[dev.name].conf_16n.max_v,
                              eq.last_value, eq.first_value,
                              v)
              eq:set_band(v, slider_id)
            elseif slider_id == eq.num_bands + 1 then
              v = util.linlin(mididevice[dev.name].conf_16n.min_v, mididevice[dev.name].conf_16n.max_v,
                              eq.last_value, eq.first_value,
                              v)
              eq:set_all_bands(v)
            end
          end
        end
      end

      -- ask config sump via sysex
      -- 0x1F - "1nFo"
      midi.send(dev, {0xf0, 0x7d, 0x00, 0x00, 0x1f, 0xf7})

    end
  end
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
    if menu_status == false and initializing == false and screen_dirty == true then
      pirate_radio_pages.update_pages()
      screen_dirty = false
      
    end
  end, SCREEN_FRAMERATE, -1)
  redrawtimer:start()  
end


function cleanup ()
  -- redrawtimer.free_all()
  
  -- add more cleanup code
end

