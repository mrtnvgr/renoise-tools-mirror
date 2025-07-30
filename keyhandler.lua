-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
---KEY HANDLER
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------



--up/down instrument
local function pre_kh_nav_instrument(value)
  local sii=song.selected_instrument_index
  local sin=#song.instruments
  if (value>0) then
    if (sin>=sii+value) then
      song.selected_instrument_index=sii+value
    else
      song.selected_instrument_index=1
    end
  else
    if (1<=sii+value) then
      song.selected_instrument_index=sii+value
    end
  end
end



function key_handler( dialog, key )
  --rprint(key)

  --undo & redo
  if ( key.modifiers == "control" and key.name == "z" ) then song:undo() end
  if ( key.modifiers == "control" and key.name == "y" ) then song:redo() end

  --navigator
  if (key.modifiers == "shift") and (key.name == "tab") then song:select_previous_track() end
  if not (key.modifiers == "shift") and (key.name == "tab") then song:select_next_track() end

  if ( key.name == "numpad -" ) then pre_kh_nav_instrument(-1) end
  if ( key.name == "numpad +" ) then pre_kh_nav_instrument(1) end


end
