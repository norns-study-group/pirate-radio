local comments={}

comments.current=""
comments.history={}
comments.history_index=1
comments.blink_time=3
comments.blink=comments.blink_time
function comments.init()
    -- TODO: download other comments
end


-- from https://github.com/justmat/crow_talk/blob/main/crow_talk.lua

function comments:redraw()
    screen.level(10)
    screen.rect(2, 50-10, 125, 14)
    screen.stroke()
    screen.move(5,59-10)
    local text="> " .. self.current
    if comments.blink>0 then 
        text=text.."|"
    end
    comments.blink=comments.blink-1 
    if comments.blink < -1*comments.blink_time then 
        comments.blink=comments.blink_time

    end
    screen.text(text)
end

function keyboard.char(character)
    comments.current = comments.current .. character -- add characters to my string
end

function keyboard.code(code,value)
  if value == 1 or value == 2 then -- 1 is down, 2 is held, 0 is release
    if code == "BACKSPACE" then
        comments.current = comments.current:sub(1, -2) -- erase characters from comments.current
    elseif code == "UP" then
        if #comments.history > 0 then -- make sure there's a comments.history
            if new_line then -- reset the comments.history index after pressing enter
            comments.history_index = #comments.history
            new_line = false
            else
            comments.history_index = util.clamp(comments.history_index - 1, 1, #comments.history) -- increment comments.history_index
            end
            comments.current = comments.history[comments.history_index]
        end
    elseif code == "DOWN" then
        if #comments.history > 0 and comments.history_index ~= nil then -- make sure there is a comments.history, and we are accessing it
            comments.history_index = util.clamp(comments.history_index + 1, 1, #comments.history) -- decrement comments.history_index
            comments.current = comments.history[comments.history_index]
        end
    elseif code == "ENTER" then
        table.insert(comments.history, comments.current) -- append the command to comments.history
        comments.current = "" -- clear comments.current
        new_line = true
    end
  end
end
  
return comments
