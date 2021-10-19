-- encoders and keys

local enc = function (n, delta)
  -- set variables needed by each page/example
  if n == 1 then
    -- scroll pages
    local page_increment = util.clamp(delta, -1, 1)

    local next_page = pages.index + page_increment
    if (next_page <= NUM_PAGES and next_page > 0) then
      page_scroll(page_increment)
    end
  elseif n == 2 then 
    if pages.index == 1 then
    elseif pages.index == 2 then

    elseif pages.index == 3 then

    elseif pages.index == 4 then

    elseif pages.index == 5 then

    end
  elseif n == 3 then 
    if pages.index == 1 then
      radio.dialer:set_pointer_loc(delta)
      for i=1,#radio.eq.sliders,1 do 
        radio.eq.sliders[i]:set_pointer_loc(delta)
      end
    elseif pages.index == 2 then

    elseif pages.index == 3 then

    elseif pages.index == 4 then

    elseif pages.index == 5 then

    end
  end
  screen_dirty = true
end

local key = function (n,z)
  if n == 1 then
    if z == 0 then alt_key_active = false else alt_key_active = true end
  end

  if (n == 2 and z == 0)  then 
    if pages.index == 1 then

    elseif pages.index == 2 then

    elseif pages.index == 3 then

    elseif(pages.index == 4) then

    elseif(pages.index == 5) then
            
    end
  elseif (n == 3 and z == 0)  then 
    if pages.index == 1 then

    elseif pages.index == 2 then

    elseif pages.index == 3 then

    elseif(pages.index == 4) then

    elseif(pages.index == 5) then
            
    end
  end
  screen_dirty = true
end

return{
  enc=enc,
  key=key
}
