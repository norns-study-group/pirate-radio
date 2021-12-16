local radio = {}

radio.dial=70
radio.playlists={}
radio.pirate_radio_enabled=false
radio.synced=false

function radio.init()
    engine.new(#radio_stations) -- setup radio mwith 3 bands
    -- position their bands
    for i,station in ipairs(radio_stations) do
        --              id  band bandwidth
        engine.band(i-1,station.band,station.bandwidth)
    end
    -- radio.create_playlist_from_tapes()
    radio.create_weather_station()

    -- startup dust2dust
    dust2dust:receive(function(data)
	if data==nil then 
	    do return end 
        end
	print("received data from dust2dust: "..json.encode(data))
        if data.message=="give-sync" and radio.synced~=true then 
            print("radio.init: give-sync")
            print(json.encode(data))
            radio.synced=radio.create_playlists_from_sync(data)
        elseif data.message=="need-sync" and radio.pirate_radio_enabled then 
            print("radio.init: need-sync")
            -- send out this stations syncing
            oscin.get_engine_state(function(engine_state)
                local send_data={message="give-sync"}
                send_data.playlists=radio.playlists
                send_data.engine_state=engine_state
                dust2dust:send(send_data)
            end)
        end
    end) 
end

function radio.clear_all()
    for i=1,#radio_stations do 
        engine.clearFiles(i-1)
    end
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
        engine.setCrossfade(0,0.5);
        -- engine.refresh()
    end
end

function radio.add_file_to_station(station,fname)
    print("adding to station "..station.." ("..radio_stations[station].band.."): "..fname)
    table.insert(radio.playlists,{fname=fname,station=station})
    engine.addFile(station-1,fname) --is 0-indexed
end

function radio.clear_stations()
    print("radio.clear_stations")
    -- clear playlists
    for i=1,#radio_stations-1 do
        engine.clearFiles(i)
    end
    radio.playlists={}
end

function radio.create_playlist_from_tapes()
    radio.clear_stations()

    -- add randomly
    math.randomseed(os.time())
    local files=util.scandir(_path.audio.."tape")
    files=fn.shuffle(files)
    for _, f in ipairs(files) do
        if string.find(f,".wav") then 
            -- assign randomly
            local station=math.random(1,#radio_stations-1)
            local fname=_path.audio.."tape/"..f
            radio.add_file_to_station(station,fname)
        end
    end

    -- make sure to refresh the engine
    engine.refresh()
end

function radio.create_playlists_from_sync(data)
    print("radio.create_playlists_from_sync")
    if data.playlists==nil then 
        print("create_playlists_from_sync: no playlists")
        do return end 
    end
    if #data.playlists<2 then 
        print("create_playlists_from_sync: not enough playlists")
        do return end 
    end
    -- make sure files exists
    local all_files_exist=true
    for i,v in ipairs(data.playlists) do
        if not util.file_exists(v.fname) then
            all_files_exist=false
        end
    end
    if not all_files_exist then 
        print("create_playlists_from_sync: all files do not exist")
        do return end 
    end

    radio.clear_stations()

    for i,v in ipairs(data.playlists) do
        radio.add_file_to_station(v.station,v.fname)
    end

    -- use the engine state to play a song from a current spot
    for _,v in ipairs(data.engine_state) do
      print("syncing station",v.station,v.playlist,v.file,v.pos)
      engine.syncStation(math.floor(tonumber(v.station)),math.floor(tonumber(v.playlist)),v.file,tonumber(v.pos))
    end

    radio.pirate_radio_enabled=true
    return true
end

function radio.create_playlists_from_pirate_radio()
    print("radio.create_playlists_from_pirate_radio")
    radio.clear_stations()

    -- add randomly
    math.randomseed(os.time())
    local files=util.scandir(_path.audio.."pirate-radio")
    files=fn.shuffle(files)
    for _, f in ipairs(files) do
        local fname=_path.audio.."pirate-radio/"..f
        _,_,ext=fn.path_split(fname)
        if ext=="ogg" then 
            print(fname)
            local metadata=fn.audio_metadata(fname)
            if metadata~=nil then 
                local station_index=radio.index_of_station(metadata.metaband)
                if station_index~=nil then 
                    radio.add_file_to_station(station_index,fname)
                end
             end 
        end
    end

    -- make sure to refresh the engine
    engine.refresh()
    radio.pirate_radio_enabled=true
end


function radio.index_of_station(band)
    if band==nil then 
        do return end 
    end
    for i,station in ipairs(radio_stations) do
        if tonumber(station.band)==tonumber(band) then 
            return i
        end
    end
end



return radio
