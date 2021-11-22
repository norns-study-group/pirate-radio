local radio = {}

radio.bands={89.8, 94.7, 103.3}
radio.dial=70
radio.playlists={}
radio.synced=false

function radio.init()
    engine.new(#radio.bands) -- setup radio mwith 3 bands
    -- position their bands
    for i,band in ipairs(radio.bands) do
        --              id  band bandwidth
        engine.band(i-1,band,0.5)
    end
    radio.create_playlist_from_tapes()
    radio.create_weather_station()

    -- startup dust2dust
    dust2dust:receive(function(data)
        if data.message=="sync-radio" and radio.synced==false then 

        end
    end) 
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
    radio.clear_stations()

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

function radio.add_file_to_station(station,fname)
    if radio.playlists[station]==nil then 
        radio.playlists[station]={}
    end
    table.insert(radio.playlists[station],fname)
    engine.addFile(station,fname)
end

function radio.clear_stations()
    -- clear playlists
    for i=1,#radio.bands-1 do
        engine.clearFiles(i)
    end
    radio.playlists={}
end

function radio.create_playlists_from_pirate_radio_w_bands()
    radio.clear_stations()

    -- add randomly
    math.randomseed(os.time())
    local files=util.scandir(_path.audio.."pirate-radio")
    for _, f in ipairs(files) do
        if string.find(f,".ogg") then 
            local data={}
            local metadata_file=f..".json"
            if util.file_exists(metadata_file) then 
                data=fn.load_json(metadata_file)
            end
            -- TODO check if there is data for its band
            -- TODO add a continue in this for loop please
            local fname=_path.audio.."pirate-radio/"..f
            radio.add_file_to_station(station,fname)
        end
    end

    -- make sure to refresh the engine
    engine.refresh()
end

function radio.create_playlists_from_pirate_radio_randomly()
    radio.clear_stations()

    -- add randomly
    math.randomseed(os.time())
    local files=util.scandir(_path.audio.."pirate-radio")
    for _, f in ipairs(files) do
        if string.find(f,".ogg") then 
            -- assign randomly
            local station=math.random(1,#radio.bands-1)
            local fname=_path.audio.."pirate-radio/"..f
            radio.add_file_to_station(station,fname)
        end
    end

    -- make sure to refresh the engine
    engine.refresh()
end

return radio
