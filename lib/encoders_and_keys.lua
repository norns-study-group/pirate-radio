-- encoders and keys

local enc = function (n, delta)
  set_from_encoder = true
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
      eq:select_eq_band(delta)
    elseif pages.index == 3 then

    elseif pages.index == 4 then

    elseif pages.index == 5 then

    end
  elseif n == 3 then 
    if pages.index == 1 then
      params:delta("dial",delta)
    elseif pages.index == 2 then
      if alt_key_active == false then
        eq:set_selected_band_rel(delta)
      else
        eq:set_all_bands_rel(delta)
      end 
    elseif pages.index == 3 then

    elseif pages.index == 4 then

    elseif pages.index == 5 then

    end
  end
  screen_dirty = true
  set_from_encoder = false
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
