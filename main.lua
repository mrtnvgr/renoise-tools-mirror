-----------
--song menu
-----------
renoise.tool():add_menu_entry {
  name = "Main Menu:Song:Missing Plugins Info Simplified...",
  invoke = function()main()end  
}

---------------
function main()
---------------
  
  local instruments_string = "MISSING Instruments:\n\n"
  --song object
  local song = renoise.song()
  
  --loop instruments
  ------------------
  for inst = 1,#song.instruments do
    
    --check for present samples
    local samples = true
    if #song:instrument(inst).samples == 0 or song:instrument(inst).samples[1].name == "" then
      samples = false 
    end
  
    --if empty name, 0 samples and no plug loaded then it is likely a missing plug (could be user made test separator in list though)
    if (song:instrument(inst).name ~= "") and 
       (samples == false) and
       (song:instrument(inst).plugin_properties.plugin_loaded == false) then
      --add instrument to GUI printout string
      instruments_string = instruments_string..song:instrument(inst).name.."\n"
    end
  end
  
  --table to hold missing plug fx names (used so we don't add multiple entries for the same plug)
  local missing_fx = "MISSING Effects:\n\n"
  local missing_plugs_tab = {}
   
  --loop tracks (for fx)
  ----------------------
  for trk = 1,#song.tracks do
    local track = song:track(trk)
    --loop devices
    for i = 2, #track.devices do
      
      if #track:device(i).parameters == 0 or
        track:device(i):parameter(1).name == "PlugInParameter" then
        --flag
        local already_added = false
        --loop table of plugs already added
        for plug = 1,#missing_plugs_tab do
          if track:device(i).name == missing_plugs_tab[plug] then
            already_added = true
            break
          end
        end
        --add name into missing plugs string
        if already_added == false then
          --update string
          missing_fx = missing_fx..track:device(i).name.."\n"
          --update table (checked in above loop, already_added flag)
          table.insert(missing_plugs_tab,track:device(i).name)
        end
      end
    end
  end
  
  --rprint(missing_plugs)
  local all_plugs_string = instruments_string.."\n"..missing_fx
  
  --Script dialog
  renoise.app():show_message(all_plugs_string)
end




