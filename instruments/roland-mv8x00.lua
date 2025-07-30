--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Roland MV8x00 Support
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function mv0_is_valid_file(d)
  -- Checks to see if this is a valid mv0 file type (0, 1 on error)
  if read_string_from_memory(d, 1, 4) == "MVFF" then
    -- valid file
    return true
  else
    return false
  end
end


function mv0_import(filename)
  -- Main import function for mv0 files
  local d = ""
  local instrument = renoise.song().selected_instrument
  local working = true
  local start_pos = 0
  local chunk_start = 0
  local chunk_len = 0
  local wave_start = 0
  local wave_len = 0
  local samples = {}
  local s
  local keymap = {}
  local rootnotes = {}

  renoise.app():show_status("Importing Roland MV8x00 patch...")
  
  lsb_first = false

  -- load the file into memory
  d = load_file_to_memory(filename)
  if d == "" then
    renoise.app():show_status("Couldn't open Roland MV8x00 patch file.")
    return false
  end

  -- check the validity of the file
  if not mv0_is_valid_file(d) then
    renoise.app():show_error(filename .. " is not a valid Roland MV8x00 patch file.")
    renoise.app():show_status(filename .. " is not a valid Roland MV8x00 patch file.")
    d = ""
    return false
  end
  
  
  -- parse sample chunks
  table.clear(samples)
  
  start_pos = d:find("SMPL") -- jump to start of samples
  
  while working == true do
    chunk_start = d:find("PRM ", start_pos)
    if chunk_start == nil then
      working = false
    else
      wave_start = d:find("WAVE", start_pos)
      wave_len = read_dword_from_memory(d, wave_start+4)
      
      dprint("mv0_import: wave at ",wave_start)
      dprint("mv0_import: wave len ",wave_len)
      dprint("mv0_import: sample name", read_string_from_memory(d, chunk_start+16, 12))
      
      -- TODO: check always 44.1khz/2ch/16bit
      table.insert(samples,{generate_wav(2, 44100, 16, d:sub(wave_start+9, wave_start + wave_len)),
                            read_string_from_memory(d, chunk_start+16, 12)})
      start_pos = wave_start + 4
    end
  end
  
  dprint("mv0_import: parsed ",#samples, "sample chunks successfully")


  if #samples > 254 then
    table.clear(samples)
    renoise.app():show_error("Sorry, Renoise is limited to 255 samples per instrument.  The instrument you are trying to import has more than this.")
    renoise.app():show_status(filename .. " has too many samples for Renoise!  Aborting.")
    return false
  end

  renoise.app():show_status("Importing Roland MV8x00 patch (samples)...")

  -- load samples
  instrument:clear()
  
  for i = 1, #samples do
    s = instrument:insert_sample_at(#instrument.samples)
    s.sample_buffer:load_from(samples[i][1])
    s.name = samples[i][2]
  end
  
  --renoise.app():show_message("Samples loaded successfully\n\nUnfortunately, currently keymaps cannot be imported at this time.")
  
  return true
end
  

--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
mv0_integration = { category = "instrument",
                    extensions = {"mv0"},
                    invoke = mv0_import}       

if renoise.tool():has_file_import_hook("instrument", {"mv0"}) == false then
  renoise.tool():add_file_import_hook(mv0_integration)
end
