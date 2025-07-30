--[[============================================================================
main.lua
============================================================================]]--

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()
  
end

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value


--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

local function scale_mapper(new_scale, octave, chord_i, chord_i_oct, base_scale) 

  -- Bringing the keyzone editor into focus
  renoise.app().window.active_middle_frame=3 

  local ins = renoise.song().selected_instrument_index -- Currently works on selected sample
  local sample_index = 1 -- A constant for now
  local note_layer = renoise.Instrument.LAYER_NOTE_ON -- The note layer that is being worked on

  local min_note = 0 -- Lowest note in the range
  local max_note = 119 -- Highest note in the range cannot exceed 119

  local base_note = 48 -- This is set for the chromatic scale, it sets the base note at C-4 for all keyzones
  local base_note_mod = 0 -- Variable for working out how much the base note is to be modified given the scale

  local chord_i_base_note = 48 -- Base note for Chord layer
  local chord_i_note_index = 0 
  local chord_mod = 0
  
  local genkeymap = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 } -- 2 octave keymap for looking up chord_i_note_index
  
  local mappings = #renoise.song().instruments[ins].sample_mappings[note_layer] -- Finds out how many existing key mappings there are in the instrument

  -- Loop that steps through total number of mappings and deletes all existing keyzones
  for n = mappings, 1, -1 do

      renoise.song().instruments[ins]:delete_sample_mapping_at( note_layer, n )

  end


  -- Loop that sets up the Sample Keyzones in the given note range
  for n = min_note, max_note, 12 do -- The main loop that counts through the entire note range, increments by octave, each octave is processed by the sub loop
      
      for note_index = 1, 12, 1 do -- The sub loop that processes each octave

          base_note_mod = note_index - new_scale[note_index] - octave[note_index] - base_scale[note_index] -- Works out how much the base note needs to be modified according to the given scale
          base_note = base_note + base_note_mod -- Does the base note modification
          renoise.song().instruments[ins]:insert_sample_mapping( note_layer, sample_index, base_note, {min_note, min_note} ) -- Creates the keyzone
          base_note = base_note - base_note_mod -- Resets the base note for the next note

          -- Checks for Chord I and processes if needed
          if chord_i[note_index] > 0 then
          chord_i_note_index = genkeymap[chord_i[note_index]+note_index] -- Works out what note index the chord note is
          chord_mod = chord_i_note_index - new_scale[chord_i_note_index] - base_scale[chord_i_note_index] -- Works out how much the chord base note needs to be modified given the scale
          chord_i_base_note = base_note - chord_i[note_index] + chord_mod - chord_i_oct[note_index] -- Sets the new Chord base note
          renoise.song().instruments[ins]:insert_sample_mapping( note_layer, sample_index, chord_i_base_note, {min_note, min_note} ) -- Creates scaled Chord I
          end
          
          min_note = min_note + 1 -- Increments for the next note
                    
      end
      
  end
  
end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()

  -- Bringing the keyzone editor into focus
  renoise.app().window.active_middle_frame=3 


  -- This block makes sure a non-modal dialog is shown once.
  -- If the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end

  
  -- Setting up the variables and presets
  vb = renoise.ViewBuilder() -- Viewbuilder shizzle

  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local DEFAULT_DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN

  local genkeymap = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }
  local scale = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" } -- The available notes used for drop dopwn lists
  local scale_def = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 } -- The scale definition, set up with a chromatic scale as a default value  
  local scale_presets_list = {  
          "Off",
          "Chromatic", 
          "Major", 
          "Minor",
          "Harmonic Minor",
          "Melodic Minor",          
          "Pentatonic",
          "Pentatonic Neutral",
          "Pentatonic Minor",
          "Pentatonic Major",
          "Blues",
          "Dorian",
          "Mixolydian",
          "Phrygian",
          "Lydian",
          "Locrian",
          "Dim Half",
          "Dim Whole",
          "Augmented",
          "Roumanian Minor",
          "Spanish Gypsy",
          "Diatonic",
          "Double Harmonic",
          "Eight Tone Spanish",
          "Enigmatic",
          "Algerian",
          "Arabian A",
          "Arabian B",
          "Balinese",
          "Byzantine",
          "Chinese",
          "Egyptian",
          "Hindu",
          "Hirajoshi",
          "Hungarian Gypsy",
          "H.Gypsy Persian",
          "Japanese A",
          "Japanese B",
          "Persian",
          "Prometheus",
          "Six Tone Symetrical",
          "Super Locrian",
          "Wholetone"
          
        }
        
  local scale_preset_defs = { }
        scale_preset_defs ["Chromatic"] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
        scale_preset_defs ["Major"] = {1, 1, 3, 3, 5, 6, 6, 8, 8, 10, 10, 12}
        scale_preset_defs ["Minor"] = {1, 1, 3, 4, 4, 6, 6, 8, 8, 9, 11, 11}
        scale_preset_defs ["Harmonic Minor"] = {1, 1, 3, 4, 4, 6, 6, 8, 8, 9, 12, 12}
        scale_preset_defs ["Melodic Minor"] = {1, 1, 3, 4, 4, 6, 6, 8, 8, 10, 12, 12}
        scale_preset_defs ["Pentatonic"] = {2, 2, 2, 4, 4, 7, 7, 7, 9, 9, 11, 11}
        scale_preset_defs ["Pentatonic Neutral"] = {1, 1, 3, 3, 3, 6, 6, 8, 8, 8, 11, 11}
        scale_preset_defs ["Pentatonic Minor"] = {1, 1, 1, 4, 4, 6, 6, 8, 8, 8, 11, 11}
        scale_preset_defs ["Pentatonic Major"] = {1, 1, 3, 3, 5, 5, 5, 8, 8, 10, 10, 10}
        scale_preset_defs ["Blues"] = {1, 1, 1, 4, 4, 6, 7, 8, 8, 8, 11, 11}
        scale_preset_defs ["Dorian"] = {1, 1, 3, 4, 4, 6, 6, 8, 8, 10, 11, 11}
        scale_preset_defs ["Mixolydian"] = {1, 1, 3, 3, 5, 6, 6, 8, 8, 10, 11, 11}
        scale_preset_defs ["Phrygian"] = {1, 2, 2, 4, 4, 6, 6, 8, 9, 9, 11, 11}
        scale_preset_defs ["Lydian"] = {1, 1, 3, 3, 5, 5, 7, 8, 8, 10, 10, 12}
        scale_preset_defs ["Locrian"] = {1, 2, 2, 4, 4, 6, 7, 7, 9, 9, 11, 11}
        scale_preset_defs ["Dim Half"] = {1, 2, 2, 4, 5, 5, 7, 8, 8, 10, 11, 11}
        scale_preset_defs ["Dim Whole"] = {1, 1, 3, 4, 4, 6, 7, 7, 9, 10, 10, 12}
        scale_preset_defs ["Augmented"] = {1, 1, 1, 4, 5, 5, 7, 7, 9, 9, 9, 12}
        scale_preset_defs ["Roumanian Minor"] = {1, 1, 3, 4, 4, 4, 7, 8, 8, 10, 11, 11}
        scale_preset_defs ["Spanish Gypsy"] = {1, 2, 2, 2, 5, 6, 6, 8, 9, 9, 11, 11}
        scale_preset_defs ["Diatonic"] = {1, 1, 3, 3, 5, 6, 6, 8, 8, 10, 10, 10}
        scale_preset_defs ["Double Harmonic"] = {1, 2, 2, 2, 5, 6, 6, 8, 9, 9, 9, 11}
        scale_preset_defs ["Eight Tone Spanish"] = {1, 2, 2, 4, 5, 6, 7, 7, 9, 9, 11, 11}
        scale_preset_defs ["Enigmatic"] = {1, 2, 2, 2, 5, 5, 7, 7, 9, 9, 11, 12}
        scale_preset_defs ["Algerian"] = {1, 1, 3, 4, 4, 6, 7, 8, 9, 9, 9, 12}
        scale_preset_defs ["Arabian A"] = {1, 1, 3, 4, 4, 6, 7, 7, 9, 10, 10, 12}
        scale_preset_defs ["Arabian B"] = {1, 1, 3, 3, 5, 6, 7, 7, 9, 9, 11, 11}
        scale_preset_defs ["Balinese"] = {1, 2, 2, 4, 4, 4, 8, 9, 9, 9, 9, 9}
        scale_preset_defs ["Byzantine"] = {1, 2, 2, 2, 5, 6, 6, 8, 9, 9, 9, 12}
        scale_preset_defs ["Chinese"] = {1, 1, 1, 1, 5, 5, 7, 8, 8, 8, 8, 12}
        scale_preset_defs ["Egyptian"] = {1, 1, 3, 3, 3, 6, 6, 8, 8, 8, 11, 11}
        scale_preset_defs ["Hindu"] = {1, 1, 3, 3, 5, 6, 6, 8, 9, 9, 11, 11}
        scale_preset_defs ["Hirajoshi"] = {1, 1, 3, 4, 4, 4, 4, 8, 9, 9, 9, 9}
        scale_preset_defs ["Hungarian Gypsy"] = {1, 1, 3, 4, 4, 4, 7, 8, 9, 9, 9, 12}
        scale_preset_defs ["H.Gypsy Persian"] = {1, 2, 2, 2, 5, 6, 6, 8, 9, 9, 9, 12}
        scale_preset_defs ["Japanese A"] = {1, 2, 2, 2, 2, 6, 6, 8, 9, 9, 9, 9}
        scale_preset_defs ["Japanese B"] = {1, 1, 3, 3, 3, 6, 6, 8, 9, 9, 9, 9}
        scale_preset_defs ["Persian"] = {1, 2, 2, 2, 5, 6, 7, 7, 9, 9, 9, 12}
        scale_preset_defs ["Prometheus"] = {1, 1, 3, 3, 5, 5, 7, 7, 7, 10, 11, 11}
        scale_preset_defs ["Six Tone Symetrical"] = {1, 2, 2, 2, 5, 6, 6, 6, 9, 10, 10, 10}
        scale_preset_defs ["Super Locrian"] = {1, 2, 2, 4, 5, 5, 7, 7, 9, 9, 11, 11}
        scale_preset_defs ["Wholetone"] = {1, 1, 3, 3, 5, 5, 7, 7, 9, 9, 11, 11}


        
  local base_key_offsets = { "Off" }
  --local base_key_offsets = { "Off", "+1", "+2", "+3", "+4", "+5", "+6", "+7", "+8", "+9", "+10", "+11" } -- for a future version
  local base_key_scaling = {0,0,0,0,0,0,0,0,0,0,0,0}
  

  local octave_id = { "C-oct", "C#-oct", "D-oct", "D#-oct", "E-oct", "F-oct", "F#-oct", "G-oct", "G#-oct", "A-oct", "A#-oct", "B-oct" } 
  local octave_shift = { "-2", "-1", "0", "+1", "+2" } -- Available octave options for the popup menu
  local octave_table = { -24, -12, 0, 12, 24} -- The corresponding note shift values for the octave popup menu
  local octave_def = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 } -- the amount of octave shift per note, set up with no shift as default
  local octave_presets_list = { 
          "All: -2", 
          "All: -1",
          "All: 0", 
          "All: +1", 
          "All: +2" 
        }

  local octave_preset_defs = { }
        octave_preset_defs ["All: 0"] = {3,3,3,3,3,3,3,3,3,3,3,3}
        octave_preset_defs ["All: +1"] = {4,4,4,4,4,4,4,4,4,4,4,4}
        octave_preset_defs ["All: -1"] = {2,2,2,2,2,2,2,2,2,2,2,2}
        octave_preset_defs ["All: +2"] = {5,5,5,5,5,5,5,5,5,5,5,5}
        octave_preset_defs ["All: -2"] = {1,1,1,1,1,1,1,1,1,1,1,1}

        
  local chord_i_id = { "C-chord_i", "C#-chord_i", "D-chord_i", "D#-chord_i", "E-chord_i", "F-chord_i", "F#-chord_i", "G-chord_i", "G#-chord_i", "A-chord_i", "A#-chord_i", "B-chord_i" } 
  local chord_options = { "Off", "+1", "+2", "+3", "+4", "+5", "+6", "+7", "+8", "+9", "+10", "+11", "+12" } -- Chord options for the popup menu
  local chord_table = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 } -- Corresponding note shift values for the chord popup menu
  local chord_presets_list = { 
          "All: Off", 
          "All: +1", 
          "All: +2", 
          "All: +3", 
          "All: +4", 
          "All: +5", 
          "All: +6", 
          "All: +7", 
          "All: +8", 
          "All: +9", 
          "All: +10", 
          "All: +11", 
          "All: +12" 
        }

  local chord_preset_defs = { }
        chord_preset_defs ["All: Off"] = {1,1,1,1,1,1,1,1,1,1,1,1}
        chord_preset_defs ["All: +1"] = {2,2,2,2,2,2,2,2,2,2,2,2}
        chord_preset_defs ["All: +2"] = {3,3,3,3,3,3,3,3,3,3,3,3}
        chord_preset_defs ["All: +3"] = {4,4,4,4,4,4,4,4,4,4,4,4}
        chord_preset_defs ["All: +4"] = {5,5,5,5,5,5,5,5,5,5,5,5}
        chord_preset_defs ["All: +5"] = {6,6,6,6,6,6,6,6,6,6,6,6}
        chord_preset_defs ["All: +6"] = {7,7,7,7,7,7,7,7,7,7,7,7}
        chord_preset_defs ["All: +7"] = {8,8,8,8,8,8,8,8,8,8,8,8}
        chord_preset_defs ["All: +8"] = {9,9,9,9,9,9,9,9,9,9,9,9}
        chord_preset_defs ["All: +9"] = {10,10,10,10,10,10,10,10,10,10,10,10}
        chord_preset_defs ["All: +10"] = {11,11,11,11,11,11,11,11,11,11,11,11}
        chord_preset_defs ["All: +11"] = {12,12,12,12,12,12,12,12,12,12,12,12}
        chord_preset_defs ["All: +12"] = {13,13,13,13,13,13,13,13,13,13,13,13}


  local chord_i_def = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 } -- Chord I setting, defaults to off
  
  local chord_i_oct_id = { "C-chord_i_oct", "C#-chord_i_oct", "D-chord_i_oct", "D#-chord_i_oct", "E-chord_i_oct", "F-chord_i_oct", "F#-chord_i_oct", "G-chord_i_oct", "G#-chord_i_oct", "A-chord_i_oct", "A#-chord_i_oct", "B-chord_i_oct" }
  
  local chord_i_octave_def = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 } -- the amount of octave shift per chord note, set up with no shift as default 

  
  -- The content of the dialog, built with the ViewBuilder.

  -- Original Note row display
  local original_note_row = vb:row {
    vb:text {
      width = 81,
      text = "Original Note:"         
    }, 

        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "C" }
        }, vb:space { width = 2 },
        
        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "C#" }
        }, vb:space { width = 2 },

        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "D" }
        }, vb:space { width = 2 },

        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "D#" }
        }, vb:space { width = 2 },

        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "E" }
        }, vb:space { width = 2 },
 
        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "F" }
        }, vb:space { width = 2 },

        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "F#" }
        }, vb:space { width = 2 },

        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "G" }
        }, vb:space { width = 2 },

        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "G#" }
        }, vb:space { width = 2 },
  
        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "A" }
        }, vb:space { width = 2 },

        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "A#" }
        }, vb:space { width = 2 },

        vb:column {
        style = "group",
        vb:text { width = 40, align = "left", text = "B" }
        }, vb:space { width = 7 },


        
        -- Preset column
        vb:column {       
        vb:text { width = 38, align = "center", text = "Base" }
        },
        
        vb:space { width = 2 },
        
        vb:column {       
        vb:text { width = 75, align = "center", text = "Scale Preset" }
        }, vb:space { width = 2 }
        
        
  }



  -- Mapped to row display
  local mapped_note_row = vb:row {
    vb:text {
      width = 80,
      text = "Mapped to:"
    },
    
        vb:popup {
        id = scale[1], -- Sets the ID as the original note name
        width = 42,
        value = 1,
        items = scale, -- Populates the drop down list
        notifier = function(popup_value)
          scale_def[1] = popup_value -- Sets the scale definition value for the note index
          end
        },  
    
        vb:popup {
        id = scale[2],
        width = 42,
        value = 2,
        items = scale,
        notifier = function(popup_value)
          scale_def[2] = popup_value
          end
        },      
    
        vb:popup {
        id = scale[3],
        width = 42,
        value = 3,
        items = scale,
        notifier = function(popup_value)
          scale_def[3] = popup_value
          end        
        },
            
        vb:popup {
        id = scale[4],
        width = 42,
        value = 4,
        items = scale,
        notifier = function(popup_value)
          scale_def[4] = popup_value
          end        
        },    

        vb:popup {
        id = scale[5],
        width = 42,
        value = 5,
        items = scale,
        notifier = function(popup_value)
          scale_def[5] = popup_value
          end        
        },

        vb:popup {
        id = scale[6],
        width = 42,
        value = 6,
        items = scale,
        notifier = function(popup_value)
          scale_def[6] = popup_value
          end        
        },

        vb:popup {
        id = scale[7],
        width = 42,
        value = 7,
        items = scale,
        notifier = function(popup_value)
          scale_def[7] = popup_value
          end
        },

        vb:popup {
        id = scale[8],
        width = 42,
        value = 8,
        items = scale,
        notifier = function(popup_value)
          scale_def[8] = popup_value
          end
        },

        vb:popup {
        id = scale[9],
        width = 42,
        value = 9,
        items = scale,
        notifier = function(popup_value)
          scale_def[9] = popup_value
          end
        },

        vb:popup {
        id = scale[10],
        width = 42,
        value = 10,
        items = scale,
        notifier = function(popup_value)
          scale_def[10] = popup_value
          end
        },

        vb:popup {
        id = scale[11],
        width = 42,
        value = 11,
        items = scale,
        notifier = function(popup_value)
          scale_def[11] = popup_value
          end
        },

        vb:popup {
        id = scale[12],
        width = 42,
        value = 12,
        items = scale,
        notifier = function(popup_value)
          scale_def[12] = popup_value
          end
        }, 


        
        
        -- Preset column (Base Key)
        vb:space { width = 5 },
        vb:popup {
        id = "base_key",
        width = 42,
        value = 1,
        items = base_key_offsets,
        notifier = function(popup_value)

        local step = popup_value -1
        local scale_copy = { }
        local target_note = 0
        local target_placement = 0
        local scale_preset_value = vb.views["scale_preset"].value
        
            -- checks to see if a scale preset is selected and if so re-sets that scale preset this is because it always transposes relative to a C scale so always needs setting back to a C scale   
            if scale_preset_value > 1 then
            
              for note = 1, 12, 1 do
              vb.views[scale[note]].value = scale_preset_defs [scale_presets_list[scale_preset_value]][note]
              end

            end


            -- copy scale into buffer for transposing
            for n = 1, 12, 1 do
                scale_copy[n] = vb.views[scale[n]].value + step -- Copies existing scale into a buffer and transposes by step value
            end

            -- copies buffer scale to popup values with the index ofset by the step value      
            for note = 1, 12, 1 do
            
                target_placement = genkeymap[(note+step)]
                target_note = genkeymap[scale_copy[note]]
                vb.views[scale[target_placement]].value = target_note
                
                
               if (target_placement - target_note) < -1 then
                    base_key_scaling[target_placement] = -12 else
                    base_key_scaling[target_placement] = 0
                    
               end
                
            end

          end
        },        
        


        
        -- Preset column (Scale Preset)
        vb:popup {
        id = "scale_preset",
        width = 75,
        value = 2,
        items = scale_presets_list,
        notifier = function(popup_value)

                     
            if popup_value > 1 then
            
            
              -- sets base key pop up list to note items
              if popup_value > 2 then
                vb.views["base_key"].items = scale
              end
                        
              -- sets the scale pattern 
              for note = 1, 12, 1 do
              vb.views[scale[note]].value = scale_preset_defs [scale_presets_list[popup_value]][note]
              end
             
              -- triggers the base key transpose (taken from base key preset column) need to make this into a function                       
              local base_key_popup_value = vb.views["base_key"].value
              local step = base_key_popup_value -1
              local scale_copy = { }
              local target_note = 0
              local target_placement = 0
            
              -- copy scale into buffer for transposing
              for n = 1, 12, 1 do
                  scale_copy[n] = vb.views[scale[n]].value + step -- Copies existing scale into a buffer and transposes by step value
              end

              -- copies buffer scale to popup values with the index ofset by the step value      
              for note = 1, 12, 1 do
              
                  target_placement = genkeymap[(note+step)]
                  target_note = genkeymap[scale_copy[note]]
                  vb.views[scale[target_placement]].value = target_note
                  
                  print(target_placement - target_note)
                  
                  if (target_placement - target_note) < -1 then
                    base_key_scaling[target_placement] = -12 else
                    base_key_scaling[target_placement] = 0
                    
                  end
              
              end 
                            
                      
            end

            -- Set base key pop up list to off if not relevant (for future have numerical offset items, allowing for custom scales to be offset)           
            if popup_value < 3 then
                  vb.views["base_key"].items = base_key_offsets
                  vb.views["base_key"].value = 1
                  
                  for n = 1, 12, 1 do -- Resets base key scaling if preset is off or chromatic
                  base_key_scaling[n] = 0
                  end
                                     
            end
            
          end
        }       
 
  }





  -- Octave shift row display
  local octave_shift_row = vb:row {
    vb:text {
      width = 80,
      text = "Octave Shift:"
    },

    
        vb:popup {
        id = octave_id[1],
        width = 42,
        value = 3,
        items = octave_shift, -- Populates the drop down list
        notifier = function(octave_popup_value)
          octave_def[1] = octave_table[octave_popup_value] -- Sets the octave definition value for the note index
          end
        },  
    
        vb:popup {
        id = octave_id[2],
        width = 42,
        value = 3,
        items = octave_shift, 
        notifier = function(octave_popup_value)
          octave_def[2] = octave_table[octave_popup_value]
          end
        },  
    
        vb:popup {
        id = octave_id[3],
        width = 42,
        value = 3,
        items = octave_shift, 
        notifier = function(octave_popup_value)
          octave_def[3] = octave_table[octave_popup_value]
          end
        },  
            
        vb:popup {
        id = octave_id[4],
        width = 42,
        value = 3,
        items = octave_shift, 
        notifier = function(octave_popup_value)
          octave_def[4] = octave_table[octave_popup_value]
          end
        },  

        vb:popup {
        id = octave_id[5],
        width = 42,
        value = 3,
        items = octave_shift, 
        notifier = function(octave_popup_value)
          octave_def[5] = octave_table[octave_popup_value]
          end
        },  

        vb:popup {
        id = octave_id[6],
        width = 42,
        value = 3,
        items = octave_shift, 
        notifier = function(octave_popup_value)
          octave_def[6] = octave_table[octave_popup_value]
          end
        },  

        vb:popup {
        id = octave_id[7],
        width = 42,
        value = 3,
        items = octave_shift, 
        notifier = function(octave_popup_value)
          octave_def[7] = octave_table[octave_popup_value]
          end
        },  

        vb:popup {
        id = octave_id[8],
        width = 42,
        value = 3,
        items = octave_shift, 
        notifier = function(octave_popup_value)
          octave_def[8] = octave_table[octave_popup_value]
          end
        },  

        vb:popup {
        id = octave_id[9],
        width = 42,
        value = 3,
        items = octave_shift, 
        notifier = function(octave_popup_value)
          octave_def[9] = octave_table[octave_popup_value]
          end
        },  

        vb:popup {
        id = octave_id[10],
        width = 42,
        value = 3,
        items = octave_shift, 
        notifier = function(octave_popup_value)
          octave_def[10] = octave_table[octave_popup_value]
          end
        },  

        vb:popup {
        id = octave_id[11],
        width = 42,
        value = 3,
        items = octave_shift, 
        notifier = function(octave_popup_value)
          octave_def[11] = octave_table[octave_popup_value]
          end
        },  

        vb:popup {
        id = octave_id[12],
        width = 42,
        value = 3,
        items = octave_shift, 
        notifier = function(octave_popup_value)
          octave_def[12] = octave_table[octave_popup_value]
          end  
        },


        
        -- Preset column
        vb:space { width = 5 },
        vb:text { align = "left", text = "Quick set:" },
        vb:space { width = 4 },
        vb:popup {
        id = "octave_preset",
        width = 62,
        value = 3,
        items = octave_presets_list,
        notifier = function(popup_value)
                                        
              for note = 1, 12, 1 do
              vb.views[octave_id[note]].value = octave_preset_defs [octave_presets_list[popup_value]][note]
              end
          
          end
        }            
  }



  -- Chord I row display
  local chord_i_row = vb:row {
    vb:text {
      width = 80,
      text = "Chord Note:"
    },
    
        vb:popup {
        id = chord_i_id[1],
        width = 42,
        value = 1, -- Default value is 'off'
        items = chord_options, -- Populates the drop down list
        notifier = function(chord_i_popup_value)
          chord_i_def[1] = chord_table[chord_i_popup_value] -- Sets the 'Chord I' value for the note index
          end
        },  
    
        vb:popup {
        id = chord_i_id[2],
        width = 42,
        value = 1, 
        items = chord_options,
        notifier = function(chord_i_popup_value)
          chord_i_def[2] = chord_table[chord_i_popup_value] 
          end
        }, 
    
        vb:popup {
        id = chord_i_id[3],
        width = 42,
        value = 1, 
        items = chord_options, 
        notifier = function(chord_i_popup_value)
          chord_i_def[3] = chord_table[chord_i_popup_value] 
          end
        }, 
            
        vb:popup {
        id = chord_i_id[4],
        width = 42,
        value = 1, 
        items = chord_options, 
        notifier = function(chord_i_popup_value)
          chord_i_def[4] = chord_table[chord_i_popup_value] 
          end
        }, 

        vb:popup {
        id = chord_i_id[5],
        width = 42,
        value = 1, 
        items = chord_options, 
        notifier = function(chord_i_popup_value)
          chord_i_def[5] = chord_table[chord_i_popup_value] 
          end
        }, 

        vb:popup {
        id = chord_i_id[6],
        width = 42,
        value = 1, 
        items = chord_options, 
        notifier = function(chord_i_popup_value)
          chord_i_def[6] = chord_table[chord_i_popup_value] 
          end
        }, 

        vb:popup {
        id = chord_i_id[7],
        width = 42,
        value = 1, 
        items = chord_options, 
        notifier = function(chord_i_popup_value)
          chord_i_def[7] = chord_table[chord_i_popup_value] 
          end
        }, 
        
        vb:popup {
        id = chord_i_id[8],
        width = 42,
        value = 1, 
        items = chord_options, 
        notifier = function(chord_i_popup_value)
          chord_i_def[8] = chord_table[chord_i_popup_value] 
          end
        },   

        vb:popup {
        id = chord_i_id[9],
        width = 42,
        value = 1, 
        items = chord_options, 
        notifier = function(chord_i_popup_value)
          chord_i_def[9] = chord_table[chord_i_popup_value] 
          end
        }, 

        vb:popup {
        id = chord_i_id[10],
        width = 42,
        value = 1, 
        items = chord_options, 
        notifier = function(chord_i_popup_value)
          chord_i_def[10] = chord_table[chord_i_popup_value] 
          end
        }, 

        vb:popup {
        id = chord_i_id[11],
        width = 42,
        value = 1, 
        items = chord_options, 
        notifier = function(chord_i_popup_value)
          chord_i_def[11] = chord_table[chord_i_popup_value] 
          end
        }, 

        vb:popup {
        id = chord_i_id[12],
        width = 42,
        value = 1, 
        items = chord_options, 
        notifier = function(chord_i_popup_value)
          chord_i_def[12] = chord_table[chord_i_popup_value] 
          end  
        },


        
        -- Preset column
        vb:space { width = 5 },
        vb:text { align = "left", text = "Quick set:" },
        vb:space { width = 4 },
        vb:popup {
        id = "chord_i_preset",
        width = 62,
        value = 1,
        items = chord_presets_list,
        notifier = function(popup_value)
          
          for note = 1, 12, 1 do
              vb.views[chord_i_id[note]].value = chord_preset_defs [chord_presets_list[popup_value]][note]
              end
          
          end
        }           
  }



  -- Chord I Octave shift row display
  local chord_i_octave_shift_row = vb:row {
    vb:text {
      width = 80,
      text = "Chord Octave:"
    },
    
        vb:popup {
        id = chord_i_oct_id[1],
        width = 42,
        value = 3,
        items = octave_shift, -- Populates the drop down list
        notifier = function(octave_popup_value)
          chord_i_octave_def[1] = octave_table[octave_popup_value] -- Sets the octave definition value for the note index
          end
        },  
    
        vb:popup {
        id = chord_i_oct_id[2],
        width = 42,
        value = 3,
        items = octave_shift,
        notifier = function(octave_popup_value)
          chord_i_octave_def[2] = octave_table[octave_popup_value] 
          end
        },   
    
        vb:popup {
        id = chord_i_oct_id[3],
        width = 42,
        value = 3,
        items = octave_shift,
        notifier = function(octave_popup_value)
          chord_i_octave_def[3] = octave_table[octave_popup_value] 
          end
        },   
            
        vb:popup {
        id = chord_i_oct_id[4],
        width = 42,
        value = 3,
        items = octave_shift,
        notifier = function(octave_popup_value)
          chord_i_octave_def[4] = octave_table[octave_popup_value] 
          end
        },   

        vb:popup {
        id = chord_i_oct_id[5],
        width = 42,
        value = 3,
        items = octave_shift,
        notifier = function(octave_popup_value)
          chord_i_octave_def[5] = octave_table[octave_popup_value] 
          end
        },   

        vb:popup {
        id = chord_i_oct_id[6],
        width = 42,
        value = 3,
        items = octave_shift,
        notifier = function(octave_popup_value)
          chord_i_octave_def[6] = octave_table[octave_popup_value] 
          end
        },   

        vb:popup {
        id = chord_i_oct_id[7],
        width = 42,
        value = 3,
        items = octave_shift,
        notifier = function(octave_popup_value)
          chord_i_octave_def[7] = octave_table[octave_popup_value] 
          end
        },   

        vb:popup {
        id = chord_i_oct_id[8],
        width = 42,
        value = 3,
        items = octave_shift,
        notifier = function(octave_popup_value)
          chord_i_octave_def[8] = octave_table[octave_popup_value] 
          end
        },   

        vb:popup {
        id = chord_i_oct_id[9],
        width = 42,
        value = 3,
        items = octave_shift,
        notifier = function(octave_popup_value)
          chord_i_octave_def[9] = octave_table[octave_popup_value] 
          end
        },   
        
        vb:popup {
        id = chord_i_oct_id[10],
        width = 42,
        value = 3,
        items = octave_shift,
        notifier = function(octave_popup_value)
          chord_i_octave_def[10] = octave_table[octave_popup_value] 
          end
        },   

        vb:popup {
        id = chord_i_oct_id[11],
        width = 42,
        value = 3,
        items = octave_shift,
        notifier = function(octave_popup_value)
          chord_i_octave_def[11] = octave_table[octave_popup_value] 
          end
        },   

        vb:popup {
        id = chord_i_oct_id[12],
        width = 42,
        value = 3,
        items = octave_shift,
        notifier = function(octave_popup_value)
          chord_i_octave_def[12] = octave_table[octave_popup_value] 
          end
        },


        
        -- Preset column
        vb:space { width = 5 },
        vb:text { align = "left", text = "Quick set:" },
        vb:space { width = 4 },
        vb:popup {
        id = "chord_octave_preset",
        width = 62,
        value = 3,
        items = octave_presets_list,
        notifier = function(popup_value)
          
          for note = 1, 12, 1 do
              vb.views[chord_i_oct_id[note]].value = octave_preset_defs [octave_presets_list[popup_value]][note]
              end
          
          end
        }   
  }





  -- Map it button
  local map_it_button_row = vb:horizontal_aligner {
    mode = "center",
    
    vb:button {
      text = "Map it",
      height = 1.2*DEFAULT_DIALOG_BUTTON_HEIGHT,
      width = 60,
      notifier = function()
          scale_mapper( scale_def, octave_def, chord_i_def, chord_i_octave_def, base_key_scaling )
          end
    }        
  }




  -- Setting up the GUI layout
  local content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    
    vb:row{
      spacing = 4*CONTENT_SPACING,

      vb:column {
        spacing = CONTENT_SPACING,
        
        original_note_row, 
        mapped_note_row,
        octave_shift_row,
        
        vb:space { height = 6 },
        
        chord_i_row,
        chord_i_octave_shift_row,
        
        vb:space { height = 8 },
        
        map_it_button_row
      },
    }
  } 

   
  -- Displays a custom dialog, user designed layout built with the ViewBuilder.   
  dialog = renoise.app():show_custom_dialog(tool_name, content)  
  
  
end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..tool_name.."...",
  invoke = show_dialog  
}

--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = show_dialog
}

--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = show_dialog
}
--]]
