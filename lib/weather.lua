local weather = {}

function weather.init()
    local cmd="curl -s wttr.in/?format=Current%20weather%20in%20%l%20is%20%C%20and%20temperature%20is%20%f%20and%20wind%20speed%20is%20%w"
    -- this is non-blocking
    norns.system_cmd(cmd,function(place)
        print("weather: "..place)
        if math.random() >0.5 then
            place = place.." and krakens lieth beneath yar vessel."
        else
            place = place.." and shining booty awaits yee beyond the great blue yonder."
        end
        file = io.open("/dev/shm/weather.txt", "w")
        io.output(file)
        io.write(place)
        io.close(file)
        local yarr=util.os_capture("espeak -k20 -s 120 -m -f /dev/shm/weather.txt -w /dev/shm/weather.wav")      
        -- setup engine
        radio.create_weather_station()
    end)
end

return weather
