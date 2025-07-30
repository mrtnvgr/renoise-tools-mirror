--------------------------------------------------------------------------------
-- Batch Rendering Tool
--
-- Copyright 2011 Martin Bealby
--
-- Main tool code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------
require "filename"
require "OneShotIdle"
require "prefs"
require "gui"


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
song_filenames = {}
filename_index = 1
render_folder = ""


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function batch_render()
  -- Queries the user for a list of songs to render to disk.
  local app = renoise.app()

  -- Are we already rendering?
  if renoise.song().rendering then
    -- yes, abort
    app:show_warning("Rendering in progress, batch render feature not available.")
    return
  end
    
  -- List of songs
  song_filenames = app:prompt_for_multiple_filenames_to_read({"*.xrns"}, "Select songs to render")
  
  -- Aborted?
  if #song_filenames == 0 then
    app:show_status("Batch rendering cancelled.")
    return 
  end
  
  -- Destination folder
  render_folder = app:prompt_for_path("Rendering destination")
  
  -- Aborted?
  if render_folder == "" then
    app:show_status("Batch rendering cancelled.")
    return 
  end
  
  -- Check for existing filenames
  local preexisting_renders = false
  
  for i = 1, #song_filenames do
    local path, filename, ext = split_filename(song_filenames[i])
    print(render_folder .. filename)

    if io.exists(render_folder .. filename .. ".wav") then
      -- yes
      print("FOUND")
      preexisting_renders = true
    end
  end
  
  if preexisting_renders then
    if app:show_prompt("Batch Render", "Some files already exist at this location.\n" ..
                                       "These will be overwritten.  Proceed?" ,
                       {"Yes", "No"}) == "No" then
      return
    end
  end
  
  -- Final check
  if app:show_prompt("Batch Render", "About to render " .. tostring(#song_filenames) ..
                                     " songs to " .. render_folder .. "\n",
                     {"Start", "Cancel"}) == "Cancel" then
    return
  end
                     
  
  -- go go rendering rangers!
  filename_index = 1
  render_pre()
end


function render_pre()
  -- Render a song
  renoise.app():show_status("Batch rendering: " .. song_filenames[filename_index])
  renoise.app():load_song(song_filenames[filename_index])
  renoise.app():show_status("Batch rendering: " .. song_filenames[filename_index])

  local path, filename, ext = split_filename(song_filenames[filename_index])
  
  -- panic (as per built in rendering)
  --renoise.song().transport:panic()
  
  -- start rendering
  renoise.song():render({sample_rate = renoise.tool().preferences.samplerate.value,
                         bit_depth = renoise.tool().preferences.bitdepth.value,
                         interpolation = renoise.tool().preferences.interpolation.value,
                         priority = renoise.tool().preferences.priority.value},
                        render_folder .. filename,
                        render_post)
end


function render_post()
  -- Call back function after rendering
  filename_index = filename_index + 1
  
  if filename_index > #song_filenames then
    -- complete
    renoise.app():show_message("Batch rendering of " .. tostring(#song_filenames)
                               .. " song(s) to " .. render_folder .. " complete.")
    renoise.app():show_status("Batch rendering of " .. tostring(#song_filenames)
                              .. " song(s) to " .. render_folder .. " complete.")
  else
    -- Start the next one
    
    --freeze_track_pre() (Cannot nest renders in Renoise 2.7, work around it)
    OneShotIdleNotifier(0.0, render_pre)
    return
  end
end


--------------------------------------------------------------------------------
-- Menu Integration
--------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = "Main Menu:File:Batch Render",
  invoke = function()
    dialog_show()
  end
}


--------------------------------------------------------------------------------
--  Startup
--------------------------------------------------------------------------------
init_prefs()
