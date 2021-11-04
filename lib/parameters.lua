-- radio params

------------------------------
-- notes and todo lsit
--
-- note: 
--
-- todo list: 
------------------------------

parameters = {}

parameters.add_params = function()
  params:add{type="control",id="dial",name="dial",controlspec=controlspec.new(70,150,'lin',0.01,94.7,'MHz',0.01/(140-80)),action=function(x)
  	radio.set_dial(x)
  end}
end

return parameters
