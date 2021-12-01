-------------------------------------------
-- notes

-------------------------------------------

local eq = {}

eq.components = {}
eq.updating_from_param = {false,false,false,false,false,false,false,false,false,false}
eq.updating_from_ui = {false,false,false,false,false,false,false,false,false,false}
function eq.init()
  if debug == true then
    eqc = eq.components
  end

  eq:build_ui()  
  eq.selected_band = 1
end

function eq:build_ui()
  local eq_x = 5
  local eq_y = 5

  local eq_left_args = {
    x=eq_x+3,
    y=eq_y+3,
    width=22,
    height=30,
    orientation='v',
    border=false,
    selected=true,
    tick_position = 'before',
    tick_labels=eq_labels,
    tick_values=eq_values
  }

  local eq_middle_args = {
    x=28,
    y=eq_y+3,
    width=7,
    height=30,
    orientation='v',
    border=false,
    tick_position = 'center',
    selected=false,
    tick_values=eq_values
  }

  local eq_right_args = {
    x=6,
    y=eq_y+3,
    width=20,
    height=30,
    orientation='v',
    border=false,
    selected=false,
    tick_position = 'after',
    tick_labels=eq_labels,
    tick_values=eq_values
  }

  local slider_group_args={
    slider_args_start=eq_left_args,
    slider_args_middle=eq_middle_args,
    slider_args_finish=eq_right_args,
    num_middle_args=8,
    x = eq_x,
    y = eq_x,
    orientation = 'v',
    selected = false,
    border = true,
    margin = 2
  }
  self.first_value = eq_middle_args.tick_values[1] 
  self.last_value = eq_middle_args.tick_values[#eq_middle_args.tick_values]
  self.bands = SliderGroup:new(slider_group_args)
  self.bands:init()
  self.num_bands = self.bands:get_num_sliders()
  for i, _ in ipairs(self.bands.sliders) do
    eq.bands.sliders[i].pointer_loc_callback=function(a) 
      local val=util.linlin(13,33,18,-18,a)
      
      engine.fxParam("band"..i,val)
      if eq.updating_from_param[i] == false then
        eq.updating_from_ui[i] = true
        params:set("eq"..i, val)
      else
        eq.updating_from_param[i] = false
      end
    end
  end
  
  for i=1,eq.num_bands,1 do
    table.insert(eq.components,eq.bands.sliders[i])
  end
  table.insert(eq.components,eq.bands)
end

function eq:set_band(value,band)
  -- print("value,band",value,band)
  local p_min = self.bands.sliders[band].pointer_min
  local p_max = self.bands.sliders[band].pointer_max
  value = util.clamp(value,self.first_value,self.last_value)
  value = util.linlin(self.first_value,self.last_value,p_min,p_max,value)
  self.bands.sliders[band]:set_pointer_loc(value,band)
end

function eq:set_all_bands(value)
  for i=1,eq.num_bands,1 do
    eq:set_band(value,i)
  end
end

function eq:set_band_rel(band,delta, from_eq)
  eq.bands.sliders[band]:set_pointer_loc_rel(delta)
  -- if from_eq == false then
  --   params:set("eq"..band, delta)
  -- end
end

function eq:set_selected_band_rel(delta)
  for i=1,eq.num_bands,1 do
    if eq.bands.sliders[i].selected == true then
      eq.bands.sliders[i]:set_pointer_loc_rel(delta)
    end
  end
end

function eq:set_all_bands_rel(delta)
  for i=1,eq.num_bands,1 do
      eq.bands.sliders[i]:set_pointer_loc_rel(delta)
  end
end

function eq:select_eq_band(delta)
  -- clear all the currently selected band
  self.bands:select('none')
  local new_band = self.selected_band and delta + self.selected_band or 1
  new_band = util.clamp(new_band,1,self.num_bands)
  self.bands:select(new_band)
  print("new_band",new_band)
  self.selected_band = new_band
end

function eq:redraw()
  -- draw the ui here
  for i=1,#eq.components,1 do
    self.components[i]:redraw()
  end
  screen.level(15)
  screen.move(5,51)
  screen.text('EQ: '..parameters.eq_names[params:get("eq_preset")])
end

return eq
