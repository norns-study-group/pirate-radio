-- radio params

------------------------------
-- notes and todo lsit
--
-- note: 
--
-- todo list: 
------------------------------

parameters = {}

parameters.specs = {
  TUNER = cs.def{
    min=TUNER_MIN,
    max=TUNER_MAX,
    warp='lin',
    step=0.1,
    default=math.random(TUNER_MIN,TUNER_MAX),
    quantum=0.001,
    wrap=true,
    -- units='khz'
  }
}

function parameters.save_settings(setting)
  local setting_name = setting[1]
  local setting_value = setting[2]
  pirate_radio_settings = pirate_radio_settings and pirate_radio_settings or {}
  pirate_radio_settings[setting_name] = setting_value
  tab.save(pirate_radio_settings, SETTINGS_PATH)
  print("save",SETTINGS_PATH,setting_name,setting_value)
end

function parameters.load_settings()
  pirate_radio_settings = tab.load(SETTINGS_PATH)
  for k, v in pairs(pirate_radio_settings) do
    params:set(k,v)
  end
end

function parameters.tuner_func()
  local setting_name = "tuner"
  local settings_value = params:get("tuner")
  local specs = parameters.specs
  -- print(specs.TUNER.minval,specs.TUNER.maxval,tuner.dialer.pointer_min,tuner.dialer.pointer_max, settings_value)
  tuner_val = util.linlin(specs.TUNER.minval,specs.TUNER.maxval,tuner.dialer.pointer_min,tuner.dialer.pointer_max, settings_value)
  -- print("tuner_val",tuner_val)
  -- tuner.dialer:set_pointer_loc(tuner_val)
  parameters.save_settings({setting_name,settings_value})
end

parameters.add_params = function()
  local specs = parameters.specs
  params:add_control("tuner","tuner",specs.TUNER)
  params:set_action ("tuner", parameters.tuner_func)
end

return parameters
