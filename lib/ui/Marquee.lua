local Marquee={}

-- initializer for marquee
function Marquee:new(o)
    o=o or {} -- create object if user does not provide one
    setmetatable(o,self)
    self.__index=self
    o.pos=0
    o.text=""
    o.station_text={}
    return o
end

function Marquee:draw(x,y,w)
    if self.text=="" then 
      do return end 
    end
    y=y+8
    local t=self.text
    local tw=screen.text_extents(t)
    -- pad with space
    for i=1,(w-tw) do
      t=t.." "
    end
    for i=1,10 do
       t=t.."  "..t
    end
    screen.level(15)
    screen.move(x-self.pos,y)
    screen.text(t)
    self.pos=self.pos+1
    if self.pos-tw*10>w then
      self.pos=0
    end
    screen.level(0)
    screen.rect(0,y-7,x,9)
    screen.fill()
    if x+w<128 then
      screen.rect(x+w,y-7,129,9)
      screen.fill()
    end
end

function Marquee:set_playing_info(i,filename)
  if radio_stations[i].name==nil then 
    do return end 
  end
  self.station_text[i]=radio_stations[i].name.."'"..radio_stations[i].description.."'"
  local metadata=fn.audio_metadata(filename)
  if metadata~=nil then 
    if metadata.metafile~=nil then
      self.station_text[i]=self.station_text[i].." playing "..metadata.metafile
    end
    if metadata.metaartist~=nil and metadata.metaartist~="" then 
      self.station_text[i]=self.station_text[i].." by "..metadata.metaartist
    end
  end
  self:update_playing_info(params:get("tuner"))
end

function Marquee:update_playing_info(band)
  local closest_station=0
  for i,v in ipairs(radio_stations) do
    if math.abs(band-v.band)<v.bandwidth then 
      closest_station=i
    end
  end
  if closest_station==0 then 
    self.text=""
    do return end 
  end
  local i=closest_station
  if self.station_text[i]~=nil then 
    self.text=self.station_text[i]
  end
end

return Marquee

