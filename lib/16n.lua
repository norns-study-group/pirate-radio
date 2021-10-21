
local _16n = {}


-- ------------------------------------------------------------------------
-- SYSEX

-- 0x1F - "1nFo"
_16n.request_sysex_config_dump = function(midi_dev)
  midi.send(midi_dev, {0xf0, 0x7d, 0x00, 0x00, 0x1f, 0xf7})
end

-- 0x0F - "c0nFig"
_16n.is_sysex_config_dump = function(sysex_payload)
  return (sysex_payload[2] == 0x7d and sysex_payload[3] == 0x00 and sysex_payload[4] == 0x00
          and sysex_payload[5] == 0x0f)
end

_16n.parse_sysex_config_dump = function(sysex_payload)
  local i = 6 + 4 -- offset
  local led_power_on = false
  local led_data_blink = false
  local rot = false
  local min_v = 0
  local max_v = 127
  local raw_min_v = 0
  local raw_max_v = 0
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
  raw_min_v = (sysex_payload[i+5] << 8) + sysex_payload[i+4]
  raw_max_v = (sysex_payload[i+7] << 8) + sysex_payload[i+6]

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
    raw_min_v = raw_min_v,
    raw_max_v = raw_max_v,
    usb_ch = usb_ch_list,
    trs_ch = trs_ch_list,
    usb_cc = usb_cc_list,
    trs_cc = trs_cc_list,
  }
end


-- ------------------------------------------------------------------------
-- PLUG'N'PLAY MIDI BINDING

local dev_16n=nil
local midi_16n=nil
local conf_16n=nil


_16n.init = function(cc_cb_fn)
  for _,dev in pairs(midi.devices) do
    if dev.name~=nil and dev.name == "16n" then
      print("detected 16n, will lookup its confif via sysex")

      dev_16n = dev
      midi_16n = midi.connect(dev.port)

      local is_sysex_dump_on = false
      local sysex_payload = {}

      midi_16n.event=function(data)
        local d=midi.to_msg(data)

        if is_sysex_dump_on then
          for _, b in pairs(data) do
            table.insert(sysex_payload, b)
            if b == 0xf7 then
              is_sysex_dump_on = false
              if _16n.is_sysex_config_dump(sysex_payload) then
                conf_16n = _16n.parse_sysex_config_dump(sysex_payload)
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
        elseif d.type == 'cc' and conf_16n ~= nil then
          if cc_cb_fn ~= nil then
            cc_cb_fn(d)
          end
        end
      end

      -- ask config dump via sysex
      _16n.request_sysex_config_dump(dev_16n)

      break
    end
  end
end


-- ------------------------------------------------------------------------
-- CONF ACCESSORS (STATEFUL)

local function mustHaveConf()
  if conf_16n == nil then
    error("Attempted to access 16n configuration while the later didn't get retrieved.")
  end
end

_16n.cc_2_slider_id = function(cc)
  mustHaveConf()

  local slider_id = nil
  for i, slider_cc in pairs(conf_16n.usb_cc) do
    if slider_cc == cc then
      slider_id = i
    end
  end

  return slider_id
end

_16n.min_v = function()
  mustHaveConf()
  return conf_16n.min_v
end

_16n.max_v = function()
  mustHaveConf()
  return conf_16n.max_v
end


-- ------------------------------------------------------------------------

return _16n
