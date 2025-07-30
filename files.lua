--------------------------------------------------------------------------------
-- SysEx Handler and Librarian
--
-- Copyright 2011 Martin Bealby
--
-- File Handling and Browser Interfacing
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function load_and_send_syx_file(filename)
  -- Wrapper function for calling from the FileBrowser
  local message = load_syx_file(filename)
  if message == false then
    return false
  else
    send_sysex(message)
    return true
  end
end


function prompt_load_and_send_syx_file()
  -- Wrapper function for calling from the Renoise menu
  local filename = renoise.app():prompt_for_filename_to_read({"*.syx"}, "SysEx file to transmit")
  
  if filename == "" then
    -- Cancelled
    renoise.app():show_status("SysEx file loading cancelled.")
    return false
  else
    -- Got file name
    load_and_send_syx_file(filename)
  end
end


function load_syx_file(filename)
  -- Load the specified 'syx' format file , convert to 'table' form to be used
  -- in the send functions and try to send it.
  local d = ""
  local f_in = io.open(filename, "rb")
  local midi_table = {}
  
  -- Did we open the file successfully
  if f_in == nil then
    renoise.app():show_status("Couldn't open 'syx' file: " .. filename .. ".")
    return false
  end
  
  -- Load the file into memory
  f_in:seek("set")
  d = f_in:read("*a") 
  f_in:close()
  
  -- Convert to table
  for i = 1,d:len() do
    table.insert(midi_table, d:sub(i,i):byte())
  end
  
  d=""
  
  -- Validity check
  if midi_table[1] ~= 0xF0 then
    midi_table = {}
    renoise.app():show_error(filename .. " is not a valid SysEx file.")
    return false
  end
  
 

  -- Return table
  return midi_table
end


function save_syx_file(message)
  -- Converts the midi message into the binary 'syx' format and saves it  
  local data = ""
  
  -- Get filename
  local filename = renoise.app():prompt_for_filename_to_write(".syx", "Save SysEx as")
  if filename == "" then
    -- Abort
    renoise.app():show_status("SysEx saving aborted")
    return
  end
  
  -- Convert data
  for i = 1, #message do
    data = data .. string.char(message[i])
  end

  -- Open file handle
  local f_out = io.open(filename, "wb")
  
  -- Did we open the file successfully
  if f_out == nil then
    renoise.app():show_status("Couldn't open 'syx' file for writing: " .. filename .. ".")
    return
  end
  
  -- Write file
  f_out:seek("set")
  f_out:write(data)
  f_out:flush()
  f_out:close()
  
  -- Report to user
  renoise.app():show_status("SysEx saved successfully as: " .. filename .. ".")
end

--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
syx_integration = { category = "instrument",
                    extensions = {"syx"},
                    invoke = load_and_send_syx_file}  -- returns true

if renoise.tool():has_file_import_hook("instrument", {"syx"}) == false then
  renoise.tool():add_file_import_hook(syx_integration)
end
