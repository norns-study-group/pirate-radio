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
magic_eye = include "pirate-radio/lib/magic_eye"
eq = include "pirate-radio/lib/eq"
_16n = include "pirate-radio/lib/16n"
visualizer = include "pirate-radio/lib/visualizer"

-- components
AbstractComponent = include "pirate-radio/lib/ui/AbstractComponent"
Slider = include "pirate-radio/lib/ui/Slider"
SliderGroup = include "pirate-radio/lib/ui/SliderGroup"
Marquee = include "pirate-radio/lib/ui/Marquee"

-- weather!
weather = include "pirate-radio/lib/weather"

-- syncing
sync = include "pirate-radio/lib/sync"

-- osc processing
oscin=include "pirate-radio/lib/oscin"

-- synchronization
dust2dust_= include "pirate-radio/lib/dust2dust"

-- radio engine
radio = include "pirate-radio/lib/radio"

-- comments
comments = include "pirate-radio/lib/comments"

-- playback
playback = include "pirate-radio/lib/playback"

-- pre-req installation
prereqs = include "pirate-radio/lib/prereqs"

-- for json

-- load json library
if not string.find(package.cpath,"/home/we/dust/code/pirate-radio/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/pirate-radio/lib/?.so"
end
json=require("cjson")

-- load the radio station list
radio_stations=fn.load_json(_path.code.."pirate-radio/lib/radio_stations.json")
