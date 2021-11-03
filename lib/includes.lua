-- required and included files

-- load the engine
engine.name="PirateRadio"

-- required for multiple files
MusicUtil = require "musicutil"
tabutil = require "tabutil"

-- required for flora.lua
UI = require "ui"
-- polls = include "flora/lib/polls"

-- required for parameters.lua
cs = require 'controlspec'

-- required for multiple files
globals = include "pirate-radio/lib/globals"

encoders_and_keys = include "pirate-radio/lib/encoders_and_keys"
pirate_radio_pages = include "pirate-radio/lib/pirate_radio_pages"

parameters = include "pirate-radio/lib/parameters"
tuner = include "pirate-radio/lib/tuner"
eq = include "pirate-radio/lib/eq"
_16n = include "pirate-radio/lib/16n"

-- components
AbstractComponent = include "pirate-radio/lib/ui/AbstractComponent"
Slider = include "pirate-radio/lib/ui/Slider"
SliderGroup = include "pirate-radio/lib/ui/SliderGroup"

-- weather!
weather = include "pirate-radio/lib/weather"

-- syncing
sync = include "pirate-radio/lib/sync"

-- osc processing
oscin=include "pirate-radio/lib/oscin"

-- radio engine
radio = include "pirate-radio/lib/radio"


