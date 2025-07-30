--[[============================================================================
com.duncanhemingway.NarrationSong.xrnx (main.lua)
============================================================================]]--

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Narration Song",
  invoke = function()
    local s = renoise.song()
    local i = s.selected_instrument_index
    local p = 1
    local spl = 1 / ((s.transport.bpm / 60) * s.transport.lpb) -- seconds per line
    local longest = { i=0, f=0 }

    while i <= #s.instruments and #s:instrument(i).samples > 0 and s:instrument(i):sample(1).sample_buffer.has_sample_data do
      if s:instrument(i):sample(1).sample_buffer.number_of_frames > longest.f then
        longest.i = i
        longest.f = s:instrument(i):sample(1).sample_buffer.number_of_frames
      end
      i = i + 1
    end
    
    if longest.i == 0 then
      renoise.app():show_warning("The selected instrument contains no sample.")
      return
    end
    
    if math.ceil((longest.f / s:instrument(longest.i):sample(1).sample_buffer.sample_rate) / spl) > 512 then -- lines needed to accommodate sample
      if renoise.app():show_prompt("Sample Too Long!", "The sample of instrument " .. ("%02X"):format(longest.i - 1) ..
                                   " is too long to fit in a single pattern. Would you like the song's BPM/LPB to be automatically adjusted?", {"OK", "Cancel"}) == "OK" then
        for lpb = s.transport.lpb, 1, -1 do
          local bpm = math.floor((60 / lpb) / ((longest.f / s:instrument(longest.i):sample(1).sample_buffer.sample_rate) / 512))
          if bpm >= 20 then
            s.transport.bpm = bpm
            s.transport.lpb = lpb
            spl = 1 / ((bpm / 60) * lpb)
            break
          elseif lpb == 1 then
            renoise.app():show_status("Narration Song: Failed to create a song.")
            renoise.app():show_warning("The sample of instrument " .. ("%02X"):format(longest.i - 1) .. " is too long to fit in a single pattern. Please make the sample smaller.")
            return
          end
        end
      else
        renoise.app():show_status("Narration Song: Song creation cancelled by user.")
        return
      end
    end
    
    if #s.sequencer.pattern_sequence > 1 then
      for slot = 1, #s.sequencer.pattern_sequence do
        s.sequencer:delete_sequence_at(1)
      end
    end

    i = s.selected_instrument_index
    while i <= #s.instruments and #s:instrument(i).samples > 0 and s:instrument(i):sample(1).sample_buffer.has_sample_data do
      s:instrument(i):sample(1).autoseek = true
      s.sequencer:insert_sequence_at(p, p)
      s:pattern(p).number_of_lines = math.ceil((s:instrument(i):sample(1).sample_buffer.number_of_frames / s:instrument(i):sample(1).sample_buffer.sample_rate) / spl)
      s:pattern(p):track(1):line(1):note_column(1).note_string = "C-4"
      s:pattern(p):track(1):line(1):note_column(1).instrument_value = i - 1
      i = i + 1
      p = p + 1
    end
    
    s.sequencer:delete_sequence_at(p)
    if i ~= s.selected_instrument_index then
      renoise.app():show_status("Narration Song: Successfully created a song for " .. i - s.selected_instrument_index .. " instruments.")
    end
  end
}
