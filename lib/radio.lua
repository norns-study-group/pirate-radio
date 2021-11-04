local radio = {}

radio.bands={89.8, 94.7, 103.3}
radio.dial=70

function radio.init()
    engine.new(#radio.bands) -- setup radio mwith 3 bands
    -- position their bands
    for i,band in ipairs(radio.bands) do
        --              id  band bandwidth
        engine.band(i-1,band,0.5)
    end
    radio.create_playlist_from_tapes()
    radio.create_weather_station()
end

function radio.set_bands(bands)
    radio.bands=bands 
    radio.init()
end

function radio.clear_all()
    for i=1,#radio.bands do 
        engine.clearFiles(i-1)
    end
end

function radio.create_playlist_from_tapes()
    -- clear playlists
    for i=1,#radio.bands-1 do
        engine.clearFiles(i)
    end

    -- add randomly
    math.randomseed(os.time())
    local files=util.scandir(_path.audio.."tape")
    for _, f in ipairs(files) do
        if string.find(f,".wav") then 
            -- assign randomly
            local station=math.random(1,#radio.bands-1)
            local fname=_path.audio.."tape/"..f
            print("adding to "..station.." "..fname)
            engine.addFile(station,fname)
        end
    end

    -- make sure to refresh the engine
    engine.refresh()
end

function radio.set_dial(dial)
    print("dial",dial)
    radio.dial=dial
    tuner:set_dial_loc(dial)
    engine.dial(dial)
end

function radio.create_weather_station()
    if util.file_exists("/dev/shm/weather.wav") then
        engine.clearFiles(0)
        engine.addFile(0,"/dev/shm/weather.wav")
        engine.refresh()
    end
end

function radio.create_playlists_from_pirate_radio()
    -- clear playlists
    for i=1,#radio.bands-1 do
        engine.clearFiles(i)
    end

    -- add randomly
    math.randomseed(os.time())
    local files=util.scandir(_path.audio.."pirate-radio")
    for _, f in ipairs(files) do
        if string.find(f,".ogg") then 
            -- assign randomly
            local station=math.random(1,#radio.bands-1)
            local fname=_path.audio.."pirate-radio/"..f
            engine.addFile(station,fname)
        end
    end

    -- make sure to refresh the engine
    engine.refresh()
end

return radio
