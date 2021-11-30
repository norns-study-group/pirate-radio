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
    -- default=math.random(TUNER_MIN,TUNER_MAX),
    default = (TUNER_MAX-TUNER_MIN)/2,
    quantum=0.001,
    wrap=true,
    -- units='khz'
  },
  DECAY_TIME = cs.def{
    min=0.1,
    max=5.0,
    warp='lin',
    step=0.1,
    -- default=math.random(TUNER_MIN,TUNER_MAX),
    default = 2,
    quantum=0.001,
    wrap=true,
    -- units='khz'
  },
  DELAY_TIME = cs.def{
    min=0,
    max=5.0,
    warp='lin',
    step=0.1,
    -- default=math.random(TUNER_MIN,TUNER_MAX),
    default = 0.2,
    quantum=0.001,
    wrap=true,
    -- units='khz'
  },
  GRAIN_DURATION = cs.def{
    min=0.001,
    max=0.2,
    warp='lin',
    step=0.001,
    -- default=math.random(TUNER_MIN,TUNER_MAX),
    default = 0.1,
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
end

function parameters.load_settings()
  pirate_radio_settings = tab.load(SETTINGS_PATH)
  if pirate_radio_settings then
    for k, v in pairs(pirate_radio_settings) do
      params:set(k,v)
    end
  end
end

function parameters.tuner_func()
  local setting_name = "tuner"
  local settings_value = params:get("tuner")
  tuner:set_dial_loc(settings_value,true)
  parameters.save_settings({setting_name,settings_value})
  -- update the marquee
  if marquee~=nil then
    marquee:update_playing_info(settings_value)
  end
end

function parameters.delay_func(val)
  engine.fxParam("effect_delay", val)
end

function parameters.delay_time_func(val)
  engine.fxParam("effect_delaytime", val)
end

function parameters.delay_decay_time_func(val)
  engine.fxParam("effect_delaydecaytime", val)
end

function parameters.granulator_func(val)
  engine.fxParam("effect_granulator", val)
end

function parameters.grain_duration_func(val)
  engine.fxParam("grainDur", val)
end

parameters.add_params = function()
  local specs = parameters.specs
  params:add_control("tuner","tuner",specs.TUNER)
  params:set_action("tuner", parameters.tuner_func)
  params:add_separator("effects")
  params:add_control("delay", "delay")
  params:set_action("delay", parameters.delay_func)
  params:add_control("delay_time", "delay time", specs.DELAY_TIME)
  params:set_action("delay_time", parameters.delay_time_func)
  params:add_control("delay_decay_time", "delay decay time", specs.DECAY_TIME)
  params:set_action("delay_decay_time", parameters.delay_decay_time_func)
  params:add_control("granulator", "granulator")
  params:set_action("granulator", parameters.granulator_func)
  params:add_control("grain_duration", "grain duration", specs.GRAIN_DURATION)
  params:set_action("grain_duration", parameters.grain_duration_func)
end

return parameters
