function os_capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

function get_weather()
  local place=os_capture("curl -s wttr.in/?0T")
  print(place)
end

function get_weather()
  local place=os_capture("curl -s wttr.in/?format=Current%20weather%20in%20%l%20is%20%C%20and%20temperature%20is%20%f%20and%20wind%20speed%20is%20%w")
  print(place)
if math.random() >0.5 then
  place = place.." and krakens lieth beneath yar vessel."
else
  place = place.." and shining booty awaits yee beyond the great blue yonder."
end
  file = io.open("weather.txt", "w")
  io.output(file)
  io.write(place)
  io.close(file)
  local yarr=os_capture("espeak -k20 -s 120 -m -f weather.txt -w weather.wav")
end

function get_weather_old()
local place1=string.match(place,"report:(.-),")
print(place1)

local osm="https://nominatim.openstreetmap.org/search.php?format=xml&q="
local curl_cmd = 'curl -s "'..osm..place1..'"'
place1="Seattle,Washington"
print(curl_cmd)
local latlon=os_capture(curl_cmd)
local lat=string.match(latlon,"lat='(.-)'")
if lat==nil then
  lat="45.12398"
end
local lon=string.match(latlon,"lon='(.-)'")
if lon==nil then
  lon=69.420
end
lat=tonumber(lat)
lon=tonumber(lon)
print(lat)
print(lon)

local noaa="'https://forecast.weather.gov/MapClick.php?lat="..lat.."&lon="..lon.."'"
print(noaa)
local foo=os_capture('curl -s '..noaa)
--print(foo)
if string.find(foo,"A point forecast is unavailable") then
  -- TODO: make a fake forecast
  print("making a fake forecast")
end
end


get_weather()
