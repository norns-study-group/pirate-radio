-- code to update/draw the pages (screens)


page_scroll = function (delta)
  print("scroll",delta)
  pages:set_index_delta(util.clamp(delta, -1, 1), false)
end

local draw_top_nav = function()
--[[
  screen.level(15)
  screen.stroke()
  screen.rect(0,0,SCREEN_SIZE.x,10)
  screen.fill()
  screen.level(0)
  screen.move(4,7)

  local nav_text
  if pages.index == 1 then
    if show_instructions == true then
      nav_text = "instructions" 
    else
      nav_text = radio.get_control_label()
    end
    screen.text(nav_text)
  elseif pages.index == 2 then
    screen.text("page 2")
  elseif pages.index == 3 then
    screen.text("page 3")
  elseif pages.index == 4 then
    screen.text("page 4")
  elseif pages.index == 5 then
    screen.text("page 5")
  end
  -- navigation marks
  screen.level(15)
  screen.rect(0,(pages.index-1)/5*10,2,2)
  screen.stroke()
  screen.update()
  ]]
end

local update_pages = function()
  if initializing == false then
    screen.clear()
    if pages.index == 1 then
      -- bounce_balls
      -- bounce.update()
      radio:redraw()
    elseif pages.index == 2 then
      
    elseif pages.index == 3 then
      
    elseif pages.index == 4 then
      
    elseif pages.index == 5 then
      
    end
    local menu_status = norns.menu.status()
    
    if menu_status == false then
      draw_top_nav()
    end
  end
end

return {
  update_pages = update_pages
}
