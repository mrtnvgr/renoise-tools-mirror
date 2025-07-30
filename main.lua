--[[============================================================================
==                                                                            ==
==                           Module Splitter V2.02                            ==
==                                                                            ==
==          Design & Coding by Clayton Hydes (clayton.hydes@me.com)           ==
==                                                                            ==
============================================================================--]]

require "process_slicer"

--------------------------------------------------------------------------------
-- Renoise Defaults
--------------------------------------------------------------------------------

MAX_TRACKS = 999
MAX_PATTERNS = 999
MAX_INSTRUMENTS = 255
MAX_SAMPLES = 256
MAX_NOTE_COLUMNS = 12
MAX_EFFECT_COLUMNS = 8
MAX_NUM_OCTAVES = 10

CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
MINI_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

SEQUENCER_TRACK = renoise.Track.TRACK_TYPE_SEQUENCER
MASTER_TRACK = renoise.Track.TRACK_TYPE_MASTER
SEND_TRACK = renoise.Track.TRACK_TYPE_SEND

MAX_PATTERN_LINES = renoise.Pattern.MAX_NUMBER_OF_LINES

EMPTY_NOTE = renoise.PatternTrackLine.EMPTY_NOTE
NOTE_OFF = renoise.PatternTrackLine.NOTE_OFF
EMPTY_INSTRUMENT = renoise.PatternTrackLine.EMPTY_INSTRUMENT
EMPTY_VOLUME = renoise.PatternTrackLine.EMPTY_VOLUME
EMPTY_PANNING = renoise.PatternTrackLine.EMPTY_PANNING
EMPTY_DELAY = renoise.PatternTrackLine.EMPTY_DELAY
EMPTY_EFFECT_NUMBER = renoise.PatternTrackLine.EMPTY_EFFECT_NUMBER
EMPTY_EFFECT_AMOUNT = renoise.PatternTrackLine.EMPTY_EFFECT_AMOUNT

SAMPLE_LOOP_MODE_OFF = renoise.Sample.LOOP_MODE_OFF
SAMPLE_LOOP_MODE_FORWARD = renoise.Sample.LOOP_MODE_FORWARD
SAMPLE_LOOP_MODE_REVERSE = renoise.Sample.LOOP_MODE_REVERSE
SAMPLE_LOOP_MODE_PING_PONG = renoise.Sample.LOOP_MODE_PING_PONG

obj_textlabel = 1
obj_button = 2 
obj_checkbox = 3
obj_switch = 4 
obj_popup = 5 
obj_chooser = 6 
obj_valuebox = 7 
obj_slider = 8 
obj_minislider = 9 
obj_textfield = 10

--------------------------------------------------------------------------------
-- Global Constants
--------------------------------------------------------------------------------

SCRIPT_TITLE = "Module Splitter"
ORIGINAL_TRACKS_NAME = "Original Track:"

MAIN_DIALOG_WIDTH = 350
SWITCH_BUTTON_WIDTH = 150
EXECUTE_BUTTON_WIDTH = 340
HELP_BUTTON_WIDTH = 20
PROGRESS_BAR_WIDTH = 350
MAX_SONGNAME_LENGTH = 30
MAX_SONGARTIST_LENGTH = 30

--------------------------------------------------------------------------------
-- Global Variables
--------------------------------------------------------------------------------

status_text = ""
debug_text = ""

num_tracks = 0
num_patterns = 0
num_instruments = 0
num_samples = 0

pattern_numbers = {}
instrument_sample_looped = {}
pattern_sequence = {}

pattern_sequence_entries = 0
orig_tracks_status = 0
note_offs_status = 0

script_started = false

current_view = nil
current_dialog = nil
current_process = nil

current_app = nil
current_song = nil

--------------------------------------------------------------------------------
-- Display Script in Tools menu
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry
{
   name = "Main Menu:Tools:Module Splitter",
   invoke = function() main_program() end
}

--------------------------------------------------------------------------------
-- Main Dialog
--------------------------------------------------------------------------------

function main_dialog()

  local vb = renoise.ViewBuilder()
  current_view = vb

  local main_dialog_title = SCRIPT_TITLE
  local main_dialog_content =

  vb:column
    {
      margin = DIALOG_MARGIN,
      spacing = DIALOG_SPACING,
      uniform = true,

      vb:column
        {
          margin = CONTROL_MARGIN,
          spacing = CONTROL_SPACING,
          style = "group",

          vb:horizontal_aligner
            {
              mode = "center",

              vb:row
                {   
                  vb:text
                    {
                      width = MAIN_DIALOG_WIDTH,
                      align = "center",
                      font = "big",
                      text = "MODULE  SPLITTER",  
                   },
                },
            },

          vb:horizontal_aligner
            {
              mode = "center",

              vb:row
                {   
                  vb:text
                    {
                      width = MAIN_DIALOG_WIDTH,
                      align = "center",
                      font = "normal",
                      text = "Version 2.02",
                   },
                },
            },

          vb:horizontal_aligner
            {
              mode = "center",

              vb:row
                {
                },
            },

          vb:horizontal_aligner
            {
              mode = "center",

              vb:row
                {   
                  vb:text
                    {
                      width = MAIN_DIALOG_WIDTH,
                      align = "center",
                      font = "normal",
                      text = "Design and Coding by Clayton Hydes",
                   },
                },      
            },
        },

      vb:column
        {
          margin = CONTROL_MARGIN,
          spacing = CONTROL_SPACING,
          style = "group",  
   
          vb:horizontal_aligner
            {
              mode = "center",

              vb:row
                {
                  vb:text
                    {
                      font = "bold",
                      text = "Song Name: ",
                    },
               
                  vb:text
                    {
                      id = "song_name_id",
                      font = "normal",
                      text = "",
                    },
                },
            },

          vb:horizontal_aligner
            {
              mode = "center",

              vb:row
                {
                  vb:text
                    {
                       font = "bold",
                       text = "Song Artist: ",
                    },

                  vb:text
                    {
                       id = "song_artist_id",
                       font = "normal",
                       text = "",
                    },
                },
            },    
        },
        
      vb:column
        {
          margin = CONTROL_MARGIN,
          spacing = CONTROL_SPACING,
          style = "group",

          vb:horizontal_aligner
            {
              mode = "center",
        
              vb:row
                {
                  vb:text
                    {
                      font = "bold",
                      text = "Number of Tracks: ",
                    },

                  vb:text
                    {
                      id = "num_tracks_id",
                      font = "normal",
                      text = "  "
                    },
                },
          },

          vb:horizontal_aligner
            {
              mode = "center",

              vb:row
                {
                  vb:text
                    {
                      font = "bold",
                      text = "Number of Patterns: ",
                    },

                  vb:text
                    {
                      id = "num_patterns_id",
                      font = "normal",
                      text = "  "
                    },
                },
            },

          vb:horizontal_aligner
            {
              mode = "center",
      
              vb:row
                {
                  vb:text
                    {
                      font = "bold",
                      text = "Number of Instruments: ",
                    },

                  vb:text
                    {
                      id = "num_instruments_id",
                      font = "normal",
                      text = "  "
                    },
                },
           },
           
          vb:horizontal_aligner
            {
              mode = "center",
        
              vb:row
                {
                  vb:text
                    {
                      font = "bold",
                      text = "Number of Samples: ",
                    },

                  vb:text
                    {
                      id = "num_samples_id",
                      font = "normal",
                      text = " "
                    },
                },
            },
        },

       vb:column
        {
          margin = CONTROL_MARGIN,
          spacing = CONTROL_SPACING,
          style = "group",

          vb:horizontal_aligner
            {
              mode = "left",

              vb:row
                {

                vb:text
                  {
                    font = "bold",
                    text = "     Original Tracks Processing",
                  },

                vb:text
                    {
                      font = "bold",
                      text = "       Instruments to 'Note Off'",
                    },
                },
            },

          vb:horizontal_aligner
            {
              mode = "center",

              vb:row
                {
                vb:switch
                  {
                    width = SWITCH_BUTTON_WIDTH,
                    height = CONTROL_HEIGHT,
                    value = orig_tracks_status,
                    items = {"Keep", "Mute", "Delete"},
                    notifier = function(value)
                      orig_tracks_status = value
                    end,
                  },

                vb:text
                  {
                  },

                vb:switch
                  {
                    width = SWITCH_BUTTON_WIDTH,
                    height = CONTROL_HEIGHT,
                    value = note_offs_status,
                    items = {"None", "Looped", "All"},
                    notifier = function(value)
                      note_offs_status = value
                   end,
                  },
                },
            },

          vb:horizontal_aligner
            {
              vb:row
                {
                },
            },
        },

       vb:column
        {
          margin = CONTROL_MARGIN,
          spacing = CONTROL_SPACING,
          style = "group",

          vb:horizontal_aligner
            {
              mode = "center",
      
              vb:row
                {
                  vb:text
                    {
                      font = "bold",
                      text = "Number of Tracks Inserted: ",
                    },

                  vb:text
                    {
                      id = "num_tracks_inserted_id",
                      font = "normal",
                      text = " "
                    },
                },
           },      
        },

      vb:column
        {
          margin = CONTROL_MARGIN,
          spacing = CONTROL_SPACING,
          style = "group",

          vb:horizontal_aligner
            {
              mode = "center",

              vb:row
                {

                vb:text
                  {
                    font = "bold",
                    text = "Conversion Progress:",
                  },
                },
            },

          vb:horizontal_aligner
            {
              mode = "center",

              vb:row
                {
                vb:minislider
                  {
                    id = "progress_bar_id",
                    width = PROGRESS_BAR_WIDTH,
                    height = CONTROL_HEIGHT,
                    min = 0,
                    max = 0,
                    value = 0,
                  },

                },
            },
        },

      vb:horizontal_aligner
        {
          mode = "center",

          vb:row
            {   
              vb:button
                {
                  id = "start_stop_button_id",
                  width = EXECUTE_BUTTON_WIDTH,
                  height = DIALOG_BUTTON_HEIGHT,
                  text = "Split Module",
                  released = function()
                    if script_started == false then
                      clear_variables()
                      clear_dialog()
                      current_process = ProcessSlicer(split_module)
                      start_process_slicer(current_process)
                    else
                      abort_script(false)
                    end
                  end
                },

              vb:button
                {
                  width = HELP_BUTTON_WIDTH,
                  height = DIALOG_BUTTON_HEIGHT,
                  text = "?",
                  released = function()
                    help_message()
                  end
                },
            },
        },
    } 

 current_dialog = current_app:show_custom_dialog(main_dialog_title,main_dialog_content,key_handler)

end

--------------------------------------------------------------------------------
-- Help Message
--------------------------------------------------------------------------------

function help_message()

  show_info([[Module Splitter allows you to split up or de-construct old Module formats that have a many instruments per track layout into a single instrument per track layout which is more suitable for editing in Renoise.

Module Splitter was entirely written for musicians who want to remix / modernise their great tunes from days gone by that were made with some of the legendary trackers around at the time.

The split / conversion process is entirely automatic and it should be the first thing you do before you start your old module transformation.  It will save you a lot of copying and pasting!

A few option buttons to help customise the final result of the conversion process to suit your needs are as follows:


Original Tracks Processing:

These buttons are for deciding what to do with the original module tracks after the conversion.

[Keep] - This option will do no further processing on the original tracks after the conversion. ie. It will keep all the original tracks enabled.

[Mute] (Default) - This option will keep and mute all the original tracks after the conversion.  Great for when you are further editing the module in Renoise and you need to refer back to the original.

[Delete] - This option will delete all the original tracks after conversion.

Note: The Mute and Delete options can be done manually at any time with Renoise by using the appropriate commands from the Pattern Sequence popup and Edit pull-down menus.


Instruments to 'Note Off':

These buttons control the behaviour of the automatic insertions of 'Note Off' commands into the module during conversion.  They need a bit of explaining, but after a few conversions you will see how they work.

[None] - No 'Note Off' commands will be automatically inserted by the conversion process.  Patterns will remain exactly the same as they are in the original module but now each note's sample will play for as long as it can.   Most modules will not sound very good after a conversion using this option due to any looped sample may now play for longer than it was originally meant too.  This happens because the note that stopped the looped sample from playing in the original module could have been using a different instrument and therefore it will now be on a different track hence not stopping the looped sample from playing anymore.  This may be the best option however if you are remixing an old module using new samples or VST instruments as you won't have to keep on removing any 'Note Off' commands that are no longer needed.

[Looped] - This option will automatically add a 'Note Off' command into the Pattern for any note that uses a looped sample and when the next note of the original track uses a different instrument.  For some songs this option may improve the playback quality of the song as instrument samples may now get played in their entirety where before they may have been 'chopped off' in the original module due to another instrument being played on the same track.  In other songs this option still might make the converted module sound funny as the extended sample playing time will wreck the overall feel / structure of the song.

[All] (Default) - This option will automatically add a 'Note Off' command into the Pattern for any note when the next note of the original track uses a different instrument.  This will keep the module sounding pretty much the same as the original does. ie. Instrument samples will play for the same amount of time as they do in the original module even though some of them still may be 'chopped off'.  If you are just doing a quick conversion to see a module being played over many more tracks than the original did and don't plan on doing any further editing, then this option should be the best.


What Module types can be split / converted?

Due to Module Splitter running within Renoise, it can process any modules / songs that Renoise can load. ie. Amiga 4/6/8 channel mods, FastTracker 2 & Impulse Tracker 2 modules.  Even Renoise songs themselves can also be split but this is un-advisable to do so as any Automation and DSP effects will not be copied to the new split tracks.


About the conversion process:

Depending on the complexity of the module, how many Tracks, Patterns and Effects it has and of course your processor speed, the splitting / conversion of the module will take some time.  The splitting / conversion process is a single pass process that will automatically insert new tracks and then copy all the Notes and Effects from the original modules Tracks into these new inserted Tracks.

The conversion process has been written to multi-task so you will actually see Renoise doing the conversion in the background and the status bar will tell you how far along the conversion is.  This also means that Renoise will be fully active during the conversion process but it is recommended that Renoise is not to be used while the conversion is running or strange results will occur!

Note: Renoise has the ability to have simultaneous notes per track.  It however does not have the ability to do simultaneous note effects per track.  For this reason, all instruments from every track of the original module will get their own new track so no note effects will be lost in the conversion.  Sometimes notes using the same instrument will get spread across multiple tracks.  If you want to combine any tracks that use the same instrument after the conversion, this can be easily achieved using the Renoise pattern advanced edit functions.


I hope you find this utility useful and a big time saver when working on your retro module conversions.  I did write this tool for myself but have decided to tidy it up a bit and release it so everyone can enjoy and hopefully benefit from it!


  Clay, Nov 2010
  ]])

end

--------------------------------------------------------------------------------
-- Key Handler
--------------------------------------------------------------------------------

function key_handler(dialog, key)

  if (key.modifiers == "" and key.name == "esc") then
    abort_script(false)  
  end
end

--------------------------------------------------------------------------------
-- Help Dialog
--------------------------------------------------------------------------------

function show_info(info_message)
 
  local info_title = "Module Splitter Info"
  local info_buttons = {"OK"}

   current_app:show_prompt(info_title,tostring(info_message),info_buttons)

end

--------------------------------------------------------------------------------
-- Debug Dialog
--------------------------------------------------------------------------------

function show_debug(debug_message)

  local debug_title = "Variables Debug"
  local debug_buttons = {"OK"}

  current.app:show_prompt(debug_title,tostring(debug_message),debug_buttons)

end

--------------------------------------------------------------------------------
-- Main Program
--------------------------------------------------------------------------------

function main_program()

  if (not current_dialog) or (not current_dialog.visible) then
    current_app = renoise.app()
    current_song = renoise.song()
    script_started = false
    orig_tracks_status = 2
    note_offs_status = 3
    main_dialog()
  end

end

--------------------------------------------------------------------------------
-- Clear Variables
--------------------------------------------------------------------------------

function clear_variables()

  script_started = true
  pattern_numbers = {}
  instrument_sample_looped = {}
  pattern_sequence = {}
  show_status("")

end

--------------------------------------------------------------------------------
-- Clear Dialog
--------------------------------------------------------------------------------

function clear_dialog()

  if script_started == true then
    current_view.views.song_name_id.text = ""
    current_view.views.song_artist_id.text = ""
    current_view.views.num_tracks_id.text = ""
    current_view.views.num_patterns_id.text = ""
    current_view.views.num_instruments_id.text = ""
    current_view.views.num_samples_id.text = ""
    current_view.views.num_tracks_inserted_id.text = ""
    show_split_progress(0,0,0)
    current_view.views.start_stop_button_id.text = "Abort Splitting Module / Song"
  else
    current_view.views.start_stop_button_id.text = "Split Module"
  end

end

--------------------------------------------------------------------------------
-- Start Process Slicer
--------------------------------------------------------------------------------

function start_process_slicer(process)

  if (not process) or (not process:running()) then
    process:start()
  end

end

--------------------------------------------------------------------------------
-- Stop Process Slicer
--------------------------------------------------------------------------------

function stop_process_slicer(process)
  
  if process and process:running() then
    process:stop()
  end

end

--------------------------------------------------------------------------------
-- Show Status
--------------------------------------------------------------------------------

function show_status(status_message)
 
  current_app:show_status(status_message)  

end

--------------------------------------------------------------------------------
-- Show Split Progress
--------------------------------------------------------------------------------

function show_split_progress(start,finish,value)

  current_view.views.progress_bar_id.min = start
  current_view.views.progress_bar_id.max = finish
  current_view.views.progress_bar_id.value = value

end

--------------------------------------------------------------------------------
-- Check Dialog Close
--------------------------------------------------------------------------------

function check_dialog_close()

  coroutine.yield()
  if (not current_dialog) or (not current_dialog.visible) then
    return true
  else
    return false
  end

end

--------------------------------------------------------------------------------
-- Abort Script
--------------------------------------------------------------------------------

function abort_script(dialog_closed)

  if dialog_closed == false then
    if current_dialog or current_dialog.visible then
      current_dialog:close()
    end
    stop_process_slicer(current_process)
  end  
  show_status("Aborted")

end

-------------------------------------------------------------------------------
-- Split Module
--------------------------------------------------------------------------------

function split_module()

  if check_dialog_close() == false then
    get_song_info()
  end
  if check_dialog_close() == false then
    process_module()
  end
  if check_dialog_close() == false then
    process_original_tracks()
  end
  if check_dialog_close() == false then
    script_started = false
    clear_dialog()
    show_status("Finished")
  else
    abort_script(true)
  end

end

--------------------------------------------------------------------------------
-- Process Module
--------------------------------------------------------------------------------

function process_module()

  local line_count = 0
  local instrument_track_count = 0
  local pattern_sequence_count = 0
  local curr_track = 0
  local curr_pattern = 0
  local note_off_track = 0
  local start_instrument_track = 0
  local last_instrument_track = 0
  local dest_instrument_track = 0
  local dest_effects_track = 0
  local num_tracks_inserted = 0

  local instrument_track_found = false
  local ghost_note = false

  local inserted_tracks = {}

  local note_source_line = nil
  local note_dest_line = nil
  local effect_source_line = nil
  local effect_dest_line = nil
  local note_off_dest_line = nil

  local note_value = 0
  local instrument_value = 0
  local prev_instrument_value = 0
  local volume_value = 0
  local panning_value = 0
  local delay_value = 0

  local number_value = 0
  local amount_value = 0

  num_tracks_inserted = 0 
  last_instrument_track = num_tracks

  for curr_track = 1, num_tracks do

    dest_instrument_track = 0
    dest_effects_track = 0
    pattern_sequence_count = 1
    start_instrument_track = last_instrument_track + 1

    repeat

      curr_pattern = pattern_sequence[pattern_sequence_count] 
      line_count = 0

      for pos,line in current_song.pattern_iterator:lines_in_pattern_track(curr_pattern,curr_track) do
        if (not table.is_empty(line.note_columns)) or (not table.is_empty(line.effect_columns)) then

          line_count = line_count + 1 

          status_text = "Copying Notes & Effects from original Tracks - Track: "..curr_track.."   Pattern: "..(curr_pattern - 1).."   Line: "..(line_count - 1)
          show_status(status_text)

          note_source_line = line.note_columns[1]
          effect_source_line = line.effect_columns[1]
          number_value = effect_source_line.number_value 
          amount_value = effect_source_line.amount_value

          if note_source_line.note_value ~= EMPTY_NOTE then
            note_value = note_source_line.note_value
            prev_instrument_value = instrument_value
            if note_source_line.instrument_value == EMPTY_INSTRUMENT then
              ghost_note = true
            else
              instrument_value = note_source_line.instrument_value
              ghost_note = false
            end
            volume_value = note_source_line.volume_value
            panning_value = note_source_line.panning_value
            delay_value = note_source_line.delay_value

            instrument_track_found = false 
            if last_instrument_track >= start_instrument_track then
              for instrument_track_count = start_instrument_track, last_instrument_track do
                if instrument_value == inserted_tracks[instrument_track_count - num_tracks] then
                  note_off_track = dest_instrument_track
                  dest_instrument_track = instrument_track_count
                  dest_effects_track = instrument_track_count
                  instrument_track_found = true
                  break
                end
              end
            end

            if instrument_track_found == false then
              num_tracks_inserted = num_tracks_inserted + 1
              last_instrument_track = last_instrument_track + 1 
              note_off_track = dest_instrument_track
              dest_instrument_track = last_instrument_track
              dest_effects_track = last_instrument_track
              inserted_tracks[last_instrument_track - num_tracks] = instrument_value
              current_song:insert_track_at(dest_instrument_track)
              current_song.tracks[dest_instrument_track].name = current_song.instruments[instrument_value + 1].name
            end

            note_dest_line = current_song.patterns[pattern_numbers[curr_pattern]].tracks[dest_instrument_track].lines[line_count].note_columns[1]
            note_dest_line.note_value = note_value
            
            if ghost_note == true then
              note_dest_line.instrument_value = EMPTY_INSTRUMENT
            else
              note_dest_line.instrument_value = instrument_value
            end
            note_dest_line.volume_value = volume_value
            note_dest_line.panning_value = panning_value
            note_dest_line.delay_value = delay_value

            if (((note_offs_status == 2) and (instrument_sample_looped[prev_instrument_value + 1] == true)) or (note_offs_status == 3)) and (note_off_track ~= 0) and (note_off_track ~= dest_instrument_track) then
              note_off_dest_line = current_song.patterns[pattern_numbers[curr_pattern]].tracks[note_off_track].lines[line_count].note_columns[1]
              if note_off_dest_line.note_value == EMPTY_NOTE then
                note_off_dest_line.note_value = NOTE_OFF
              end
            end
          end

          if (dest_effects_track ~= 0) and ((number_value ~= 0) or (amount_value ~= 0)) then
            effect_dest_line = current_song.patterns[pattern_numbers[curr_pattern]].tracks[dest_effects_track].lines[line_count].effect_columns[1]
            effect_dest_line.number_value = number_value
            effect_dest_line.amount_value = amount_value
          end
        end
      end

    current_view.views.num_tracks_inserted_id.text = ""..num_tracks_inserted
    show_split_progress(0,num_tracks * pattern_sequence_entries,(curr_track - 1) * pattern_sequence_entries + pattern_sequence_count)
    pattern_sequence_count = pattern_sequence_count + 1

    until (not pattern_sequence[pattern_sequence_count]) or (check_dialog_close() == true)
    
 end

end

--------------------------------------------------------------------------------
-- Process Original Tracks
--------------------------------------------------------------------------------

function process_original_tracks()

  local track_count = 0

  for track_count = 1, num_tracks do
    if orig_tracks_status < 3 then 
     current_song.tracks[track_count].name = "("..ORIGINAL_TRACKS_NAME.." "..current_song.tracks[track_count].name..")"
    end  
    if orig_tracks_status == 2 then 
      show_status("Muting original Tracks...")
      current_song.tracks[track_count]:mute()
    end
    if orig_tracks_status == 3 then 
      show_status("Deleting original Tracks...")
      current_song:delete_track_at(1)
    end    
  end

end

--------------------------------------------------------------------------------
-- Get Song Information
--------------------------------------------------------------------------------

function get_song_info()

  local song_name = ""
  local song_artist = ""
  local track_count = 0
  local pattern_count = 0
  local instrument_count = 0
  local sample_count = 0
  local sample_found = false
  local sample_looped = false

  song_name = current_song.name
  if #song_name > MAX_SONGNAME_LENGTH then
    song_name = string.sub(song_name,1,MAX_SONGNAME_LENGTH)
  end
  song_artist = current_song.artist
  if #song_artist > MAX_SONGARTIST_LENGTH then
    song_artist = string.sub(song_artist,1,MAX_SONGARTIST_LENGTH)
  end
  current_view.views.song_name_id.text = song_name
  current_view.views.song_artist_id.text = song_artist

  num_tracks = 0
  for track_count,track in ipairs(current_song.tracks) do
    show_status("Counting Tracks...")
    if (track ~= nil) and (track.type == SEQUENCER_TRACK) then
      num_tracks = num_tracks + 1
    end
  end
  current_view.views.num_tracks_id.text = ""..num_tracks

  if check_dialog_close() == true then
    return
  end

  num_patterns = 0
  for pattern_count,pattern in ipairs(current_song.patterns) do
    show_status("Counting Patterns...")
    if pattern ~= nil then
      num_patterns = num_patterns + 1
      pattern_numbers[num_patterns] = pattern_count
    end
  end
  current_view.views.num_patterns_id.text = ""..num_patterns
  
  if check_dialog_close() == true then
    return
  end

  pattern_sequence = current_song.sequencer.pattern_sequence
  pattern_sequence_entries = 0
  for pattern_count,patternsequencer in ipairs(current_song.sequencer.pattern_sequence) do
    show_status("Counting number of Patterns used...")
    if patternsequencer ~= nil then
      pattern_sequence_entries = pattern_sequence_entries + 1
    end
  end

  if check_dialog_close() == true then
    return
  end

  num_samples = 0
  num_instruments = 0
  for instrument_count,instrument in ipairs(current_song.instruments) do
    sample_found = false
    sample_looped = false
    for sample_count,sample in ipairs(instrument.samples) do
      if sample.sample_buffer.has_sample_data == true then
        sample_found = true
        num_samples = num_samples + 1
        if sample.loop_mode ~= SAMPLE_LOOP_MODE_OFF then
          sample_looped = true
        end
      end
    end
    instrument_sample_looped[instrument_count] = sample_looped
    if sample_found == true then
      num_instruments = num_instruments + 1
    end
    current_view.views.num_instruments_id.text = ""..num_instruments
    current_view.views.num_samples_id.text = ""..num_samples

     if check_dialog_close() == true then
       return
     end

   end

end

