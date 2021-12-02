local playback={
  rec=0,
  current=0,
  new=0,
  update=0,
  tt={},
  tt_start_beats=0,
  tt_start_time=0,
  seconds_max=250,
  position_changed=false,
  do_loop=0,
  go_loop=0,
  live_sign=10,
}

function playback.init()
  -- initialize array to hold the current times
  playback.tt={}
  for i=0,playback.seconds_max do
    table.insert(playback.tt,0)
  end

  -- initialize softcut
  playback:reroute_audio(true)
  playback:init_softcut()

  -- init parameters
  -- TODO: put a separator or a group or something
  params:add_group("playback",4)
  params:add_control("playback_rate","rate",controlspec.new(-1,1,'lin',0.05,1,'s',0.05/2))
  params:set_action("playback_rate",function(x)
    playback:rate(x)
  end)
  params:add_control("playback_position","position",controlspec.new(0,playback.seconds_max,'lin',0.05,0,'s',0.05/playback.seconds_max))
  params:set_action("playback_position",function(x)
    playback.position_changed=true
    playback:pos(x)
  end)
  params:add_control("playback_loop1","loop start",controlspec.new(0,playback.seconds_max,'lin',0.05,0,'s',0.05/playback.seconds_max))
  params:set_action("playback_loop1",function(x)
    if playback.current<params:get("playback_loop2") then
      playback:loop(x,params:get("playback_loop2"))
    end
  end)
  params:add_control("playback_loop2","loop end",controlspec.new(0,playback.seconds_max,'lin',0.05,playback.seconds_max,'s',0.05/playback.seconds_max))
  params:set_action("playback_loop2",function(x)
    playback:loop(params:get("playback_loop1"),x)
  end)

  playback.debounce_start=15

  -- osc??
  -- osc.event=function(path,args,from)
  --   --print(path)
  --   if go_loop==1 then
  --     print("go_loop 1")
  --     params:set("playback_loop"..(params:get("playback_rate")>=0 and "1" or "2"),self.current)
  --     go_loop=0
  --   end
  --   if go_loop==2 then
  --     print("go_loop 2")
  --     params:set("playback_loop"..(params:get("playback_rate")>=0 and "2" or "1"),self.current)
  --     go_loop=0
  --   end
  -- end
end

function playback:reroute_audio(startup)
  if startup then
    -- disable default SuperCollider output (SuperCollider -> crone -> softcut)
    -- because crone also goes to output
    os.execute("jack_disconnect crone:input_5 SuperCollider:out_1")
    os.execute("jack_disconnect crone:input_6 SuperCollider:out_2")
    -- -- enable SuperCollider -> softcut directly
    os.execute("jack_connect SuperCollider:out_1 softcut:input_1")
    os.execute("jack_connect SuperCollider:out_2 softcut:input_2")
  else
    -- reset
    os.execute("jack_connect crone:input_5 SuperCollider:out_1")
    os.execute("jack_connect crone:input_6 SuperCollider:out_2")
    os.execute("jack_disconnect SuperCollider:out_1 softcut:input_1")
    os.execute("jack_disconnect SuperCollider:out_2 softcut:input_2")
  end
end

function playback:init_softcut()
  -- setup three stereo loops
  softcut.reset()
  softcut.buffer_clear()
  audio.level_eng_cut(0)
  audio.level_tape_cut(1)
  audio.level_adc_cut(1)
  for i=1,4 do
    softcut.enable(i,1)

    -- stereo loops
    if i%2==1 then
      softcut.pan(i,1)
      softcut.buffer(i,1)
      softcut.level_input_cut(1,i,1)
      softcut.level_input_cut(2,i,0)
    else
      softcut.pan(i,-1)
      softcut.buffer(i,2)
      softcut.level_input_cut(1,i,0)
      softcut.level_input_cut(2,i,1)
    end

    if i>2 then
      -- recording heads
      softcut.rec(i,1)
      softcut.level(i,0.0)
      softcut.rec_level(i,1.0)
      softcut.pre_level(i,0.0)
    else
      -- playback heads
      softcut.rec(i,0)
      softcut.level(i,1.0)
      softcut.rec_level(i,0.0)
      softcut.pre_level(i,1.0)
    end
    softcut.play(i,1)
    softcut.rate(i,1)
    softcut.loop_start(i,0)
    softcut.loop_end(i,self.seconds_max)
    softcut.position(i,0)
    softcut.loop(i,1)
    softcut.fade_time(i,0.1)

    softcut.level_slew_time(i,0.4)
    softcut.rate_slew_time(i,0.4)
    softcut.pan_slew_time(i,0.4)
    softcut.recpre_slew_time(i,0.4)

    softcut.phase_quant(i,0.025)

    softcut.post_filter_dry(i,0.0)
    softcut.post_filter_lp(i,1.0)
    softcut.post_filter_rq(i,1.0)
    softcut.post_filter_fc(i,20000)

    softcut.pre_filter_dry(i,1.0)
    softcut.pre_filter_lp(i,1.0)
    softcut.pre_filter_rq(i,1.0)
    softcut.pre_filter_fc(i,20000)
  end
  softcut.event_phase(function(voice,position)
    if voice==3 then
      self.tt[math.floor(position)+1]=self:ct()
      self.rec=position
    elseif voice==1 then
      self.current=position
      if self.update==0 and not self.position_changed then
        params:set("playback_position",position,true)
      end
    end
  end)
  softcut.poll_start_phase()
  self.tt[1]=self:ct()
  self.tt_start_beats=self.tt[1]
  -- set according to local time zone
  self.tt_start_time=os.time({year=os.date("%Y"), month=os.date("%m"), day=os.date("%d"), hour=os.date("%H"), min=os.date("%M"),sec=os.date("%S")})
end

function playback:ct()
  return clock.get_beats()*clock.get_beat_sec()
end


function playback:update_state()
  if self.debounce_start>0 then
    self.debounce_start=self.debounce_start-1
    if self.debounce_start==0 then
      self:frontier()
    end
  end
  if self.update>0 then
    self.update=self.update-1
    if self.update==0 then
      for i=1,2 do
        softcut.position(i,self.new)
      end
    end
  end
end

function playback:frontier()
  self.position_changed=false
  self:loop(0,self.seconds_max)
  self:pos(self.rec-1)
end

function playback:pos(pos)
  self.update=1
  self.new=pos
end

function playback:loop(pos1,pos2)
  local p1=pos1
  local p2=pos2
  if p1>p2 then
    p1=pos2
    p2=pos1
  end
  for i=1,2 do
    softcut.loop_start(i,p1)
    softcut.loop_end(i,p2)
  end
end

function playback:rate(r)
  for i=1,2 do
    softcut.rate(i,r)
  end
end

function playback:toggle_loop()
  self.position_changed=false
  if self.do_loop==0 then
    params:set("playback_loop"..(params:get("playback_rate")>=0 and "1" or "2"),self.current)
  elseif self.do_loop==1 then
    params:set("playback_loop"..(params:get("playback_rate")>=0 and "2" or "1"),self.current)
  elseif self.do_loop==2 then
    if params:get("playback_rate")<0 then
      params:set("playback_loop2",0)
    else
      params:set("playback_loop2",self.seconds_max)
    end
    self.do_loop=-1
  end
  self.do_loop=self.do_loop+1
end

function playback:change_rate(d)
  params:delta("playback_rate",d)
end

function playback:change_pos(d)
  params:delta("playback_position",d)
  params:set("playback_loop1",params:get("playback_position"))
  if params:get("playback_loop2")<params:get("playback_loop1") then
    params:set("playback_loop2",params:get("playback_loop1")+1)
  end
end

function playback:in_loop()
  if params:get("playback_loop2")==self.seconds_max then
    return false
  end
  return self.current>=params:get("playback_loop1") and self.current<=params:get("playback_loop2")
end

function playback:redraw()
  self:update_state()
  if self.do_loop>0 then
    screen.display_png(_path.code.."pirate-radio/art/loop"..self.do_loop..".png",115,0)
    if self.do_loop==1 then
      local tt,mtt=self:get_time_from_position(params:get("playback_loop1"))
      local ss=string.format("%.2f",tt-mtt)
      screen.level(5)
      screen.font_face(1)
      screen.font_size(8)
      screen.move(10,50)
      screen.text(os.date('%I:%M:%S',mtt)..ss:sub(2))
    else
      local tt,mtt=self:get_time_from_position(params:get("playback_loop1"))
      local ss=string.format("%.2f",tt-mtt)
      local tt2,mtt2=self:get_time_from_position(params:get("playback_loop2"))
      local ss2=string.format("%.2f",tt2-mtt2)
      screen.level(5)
      screen.font_face(1)
      screen.font_size(8)
      screen.move(10,50)
      screen.text(os.date('%I:%M:%S',mtt)..ss:sub(2).." - "..os.date('%I:%M:%S',mtt2)..ss2:sub(2))
    end
  elseif self.position_changed==true then
    tt,mtt=self:get_time_from_position(params:get("playback_position"))
    local ss=string.format("%.2f",tt-mtt)
    screen.level(5)
    screen.font_face(1)
    screen.font_size(8)
    screen.move(10,50)
    screen.text(os.date('%I:%M:%S',mtt)..ss:sub(2))
  end

  local current=self.current
  if self.update>0 then
    current=self.new
  end
  tt,mtt=self:get_time_from_position(current)
  if tt~=nil then
    screen.level(5)
    screen.font_face(40)
    screen.move(10,10)
    screen.font_size(12)
    screen.text(os.date('%a, %b %d',mtt))
    screen.move(10,30+3)
    local ss=string.format("%.2f",tt-mtt)
    ss=ss:sub(2)
    screen.level(15)
    screen.font_face(5)
    screen.font_size(22)
    screen.text(os.date('%I:%M:%S',mtt))
    screen.font_size(10)
    screen.move(127,30+3)
    screen.text_right(string.lower(os.date("%p")))
    screen.font_size(12)
    screen.move(93,23+3)
    screen.text(ss)
  end

  if math.abs(playback.rec-playback.current)<1.3 then
    screen.font_size(8)
    screen.font_face(1)
    screen.level(10)
    screen.rect(105-16,2,21,11)
    screen.stroke()
    screen.move(105+2-16,2+7)
    self.live_sign=self.live_sign-1 
    if self.live_sign<-10 then 
      self.live_sign=15
    end
    screen.level(self.live_sign>0 and 10 or 5)
    screen.text("LIVE")
  end
end

function playback:get_time_from_position(position)
  local m=self.tt[math.floor(position)+1]
  local f=position-math.floor(position)
  local n=self.tt[math.floor(position)+2]
  if n==nil then
    n=m+1
  end
  if m==nil then
    do return end
  end
  m=m*(1-f)+n*f
  local tt=m-self.tt_start_beats+self.tt_start_time
  local mtt=math.floor(tt)
  return tt,mtt
end

return playback
