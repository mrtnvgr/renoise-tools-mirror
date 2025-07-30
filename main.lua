--[[============================================================================
DJ Tools - Crossfader

Written by Thilo Geertzen aka Cie in 4/2012.
www.stepsequencer.net

v1.0: initial version with prelistening option.
v1.1: forgotten to add midi mappings for midi control
v1.2: set height of the sliders to 20
      added Blockloop section to control blockloop value via midi button
v1.21: added keybinding to Global->Tools for starting tool with a custom key combination
v1.3: added Left, Center, Right buttons: sets the master crossfader directly to the left, center or right without fading
      added Ignore button: if activated, moving the master crossfader sends no values.
============================================================================]]--

--[[============================================================================
main.lua
============================================================================]]--
local version = "1.3"

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

local dialog_margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
local dialog_spacing = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
local control_margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local control_spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
    
local track_names = {}

local dj_tools = renoise.Document.create("DJTools") {
      
  deck_a_track_nr=3;
  deck_b_track_nr=4;
  deck_a_prl_track_nr=1;
  deck_b_prl_track_nr=2;
  crossfader_value=0.5;
  deck_a_volume=1.0;
  deck_b_volume=1.0;
}
      
local ignore_mode = false; -- freeze master slider; using the master fader does not send any value

--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

-- reads names of given tracks
function load_tracks()

  track_names = {}
  for i=1,#renoise.song().tracks do 
    local track = renoise.song().tracks[i];
    table.insert(track_names, i, track.name)
  end

  rprint(track_names)
end

function calculate_volume(value, master)

  
    if value>=0.5 then
      dj_tools.deck_a_volume.value = 2*(1.0-value)
      dj_tools.deck_b_volume.value = 1.0
    end
   
    if value<0.5 then
      dj_tools.deck_a_volume.value = 1.0
      dj_tools.deck_b_volume.value = value*2
    end  
   
  if master then
    
    -- update gui
    vb.views['cf.vol.a'].text = 'Volume: '.. string.format("%.2f", dj_tools.deck_a_volume.value)
    vb.views['cf.vol.b'].text = 'Volume: '.. string.format("%.2f", dj_tools.deck_b_volume.value)
    
    -- change volume in selected tracks
    renoise.song().tracks[dj_tools.deck_a_track_nr.value].prefx_volume.value = dj_tools.deck_a_volume.value
    renoise.song().tracks[dj_tools.deck_b_track_nr.value].prefx_volume.value = dj_tools.deck_b_volume.value
  else
    -- change volume in selected tracks
    renoise.song().tracks[dj_tools.deck_a_prl_track_nr.value].prefx_volume.value = dj_tools.deck_a_volume.value
    renoise.song().tracks[dj_tools.deck_b_prl_track_nr.value].prefx_volume.value = dj_tools.deck_b_volume.value  
  end
  
end


function add_midi_mappings()

  if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:CrossfaderMaster")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:CrossfaderMaster",
      invoke = function(message)

        if (message:is_abs_value()) then
          --print(("de.cie-online.DJ-Tool:CrossfaderMaster  message.int_value: %d)"):format(message.int_value))
          vb.views['cf.mst.fader'].value = message.int_value/127
        end

      end
    }
  end
  
  if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:CrossfaderPreListen")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:CrossfaderPreListen",
      invoke = function(message)

        if (message:is_abs_value()) then
          vb.views['cf.prl.fader'].value = message.int_value/127
        end

      end
    }
  end  
  
  if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:Blockloop:1/2")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:Blockloop:1/2",
      invoke = function(message)

        if (message:is_trigger() or message:is_abs_value()) then
          set_block_loop(2)
        end
        
      end
    }
  end
  
  if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:Blockloop:1/3")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:Blockloop:1/3",
      invoke = function(message)

        if (message:is_trigger() or message:is_abs_value()) then
          set_block_loop(3)
        end
        
      end
    }
  end    
  
  if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:Blockloop:1/4")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:Blockloop:1/4",
      invoke = function(message)

        if (message:is_trigger() or message:is_abs_value()) then
          set_block_loop(4)
        end
        
      end
    }
  end  
 
  if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:Blockloop:1/5")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:Blockloop:1/5",
      invoke = function(message)

        if (message:is_trigger() or message:is_abs_value()) then
          set_block_loop(5)
        end
        
      end
    }
  end   
 
  if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:Blockloop:1/6")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:Blockloop:1/6",
      invoke = function(message)

        if (message:is_trigger() or message:is_abs_value()) then
          set_block_loop(6)
        end
        
      end
    }
  end   
 
   if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:Blockloop:1/7")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:Blockloop:1/7",
      invoke = function(message)

        if (message:is_trigger() or message:is_abs_value()) then
          set_block_loop(7)
        end
        
      end
    }
  end  
 
   if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:Blockloop:1/8")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:Blockloop:1/8",
      invoke = function(message)

        if (message:is_trigger() or message:is_abs_value()) then
          set_block_loop(8)
        end
        
      end
    }
  end  
  
  
  if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:Left")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:Left",
      invoke = function(message)

        if (message:is_trigger() or message:is_abs_value()) then
          vb.views['cf.mst.fader'].value = 0
        end
        
      end
    }
  end
  
  if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:Center")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:Center",
      invoke = function(message)

        if (message:is_trigger() or message:is_abs_value()) then
          vb.views['cf.mst.fader'].value = 0.5
        end
        
      end
    }
  end  
  
  if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:Right")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:Right",
      invoke = function(message)

        if (message:is_trigger() or message:is_abs_value()) then
          vb.views['cf.mst.fader'].value = 1
        end
        
      end
    }
  end
  
  if (renoise.tool():has_midi_mapping("de.cie-online.DJ-Tool:Ignore")~=true) then

    renoise.tool():add_midi_mapping{
      name = "de.cie-online.DJ-Tool:Ignore",
      invoke = function(message)

        if (message:is_trigger() or message:is_abs_value()) then
          set_ignore_mode()
        end
        
      end
    }
  end      
   
end


function set_block_loop(range) 

  --renoise.song().transport.loop_pattern = true
  --renoise.song().transport.loop_block_enabled = true -- does not do anything, bug?
  renoise.song().transport.loop_block_range_coeff = range
  renoise.song().transport:loop_block_move_backwards()
  renoise.song().transport:loop_block_move_backwards()
  
end

function set_ignore_mode()
  ignore_mode = not ignore_mode
  if ignore_mode then
    vb.views['ignore_button'].color = {0x7e,0x3b,0x3b}
  else
    vb.views['ignore_button'].color = {0x1e,0x1b,0x1b}
  end
end
--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()

  load_tracks()

  -- This block makes sure a non-modal dialog is shown once.
  -- If the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end
  
  -- The ViewBuilder is the basis
  vb = renoise.ViewBuilder()

  local gui = vb:column
  {
        style = "body",
        margin = dialog_margin,
        spacing = dialog_spacing,
        uniform = true,
        
        -- Blockloop buttons
        vb:text { text = "Blockloop" },
        vb:column {
  
          style = "group",
          margin = control_margin,
          spacing = control_spacing,        
          vb:row {
          
            vb:button {
              id = "block.loop.1.2",
              text = "1/2",
              midi_mapping = "de.cie-online.DJ-Tool:Blockloop:1/2",
              notifier = function() 
                set_block_loop(2)
              end 
            },
 
            vb:button {
              id = "block.loop.1.3",
              text = "1/3",
              midi_mapping = "de.cie-online.DJ-Tool:Blockloop:1/3",
              notifier = function() 
                set_block_loop(3)
              end 
            },
                       
            vb:button {
              id = "block.loop.1.4",
              text = "1/4",
              midi_mapping = "de.cie-online.DJ-Tool:Blockloop:1/4",
              notifier = function() 
                set_block_loop(4)
              end 
            },
            
            vb:button {
              id = "block.loop.1.5",
              text = "1/5",
              midi_mapping = "de.cie-online.DJ-Tool:Blockloop:1/5",
              notifier = function() 
                set_block_loop(5)
              end 
            },
            
            vb:button {
              id = "block.loop.1.6",
              text = "1/6",
              midi_mapping = "de.cie-online.DJ-Tool:Blockloop:1/6",
              notifier = function() 
                set_block_loop(6)
              end 
            },
            
            vb:button {
              id = "block.loop.1.7",
              text = "1/7",
              midi_mapping = "de.cie-online.DJ-Tool:Blockloop:1/7",
              notifier = function() 
                set_block_loop(7)
              end 
            },
            vb:button {
              id = "block.loop.1.8",
              text = "1/8",
              midi_mapping = "de.cie-online.DJ-Tool:Blockloop:1/8",
              notifier = function() 
                set_block_loop(8)
              end 
            }
          
          }
        },  
          
        -- Prelisten Block
        vb:text { text = "Cue/Prelisten" },
        vb:column {
  
          style = "group",
          margin = control_margin,
          spacing = control_spacing,
                  
          vb:row {
            width=400,
            vb:column
            {
                width=200,
                vb:text { text = "Deck A:" },
                vb:popup {
                  width=100,
                  id = 'cf.prl.track.a',
                  items = track_names,
                  bind = dj_tools.deck_a_prl_track_nr,
                }
            
            },
            vb:column
            {
                vb:text { text = "Deck B:" },
                vb:popup {
                  id = 'cf.prl.track.b',
                  width=100,
                  items = track_names,
                  bind = dj_tools.deck_b_prl_track_nr,
                }
            
            }
            
          },
          
          vb:horizontal_aligner
          {
            mode = "justify",
            vb:minislider {
                id = 'cf.prl.fader',
                value = 0.5,
                width = 200,
                height = 20,
                midi_mapping = "de.cie-online.DJ-Tool:CrossfaderPreListen",
                notifier = function(value) 
                  calculate_volume(value, false)
                end
            }
          }
    
        },      
        
        -- Master Block  
        vb:text { text = "Master" },
        vb:column {
  
          style = "group",
          margin = control_margin,
          spacing = control_spacing,
                
          vb:row {
            width=400,
            vb:column
            {
                vb:text { text = "Deck A:" },
                vb:popup {
                  id = 'cf.mst.track.a',
                  width=100,
                  items = track_names,
                  bind = dj_tools.deck_a_track_nr,
                },
                vb:text { width=200,text = "Volume: " .. dj_tools.deck_a_volume.value, id='cf.vol.a' }
            
            },
            vb:column
            {
                vb:text { text = "Deck B:" },
                vb:popup {
                  id = 'cf.mst.track.b',
                  width=100,
                  items = track_names,
                  bind = dj_tools.deck_b_track_nr,
                },
                vb:text { text = "Volume: " .. dj_tools.deck_b_volume.value, id='cf.vol.b' }                
            
            }
            
          },
          
          vb:horizontal_aligner
          {
            mode = "justify",
            vb:minislider {
                id = 'cf.mst.fader',
                value = 0.5,
                width = 200,
                height = 20,
                midi_mapping = "de.cie-online.DJ-Tool:CrossfaderMaster",
                notifier = function(value) 
                  if ignore_mode==false then
                    calculate_volume(value, true)
                  end
                end
            }
          },
          
          vb:row
          {
            width=400,
            vb:button { 
              text= 'Left',
              midi_mapping = "de.cie-online.DJ-Tool:Left",
              width=50,
              notifier = function() 
                vb.views['cf.mst.fader'].value = 0
              end
            },
            vb:text { width=75,text = '' },            
            vb:button { 
              text= 'Center',
              midi_mapping = "de.cie-online.DJ-Tool:Center",
              width=50,
              notifier = function() 
                vb.views['cf.mst.fader'].value = 0.5
              end
            },
            vb:text { width=75,text = '' },  
            vb:button { 
              text= 'Right',
              midi_mapping = "de.cie-online.DJ-Tool:Right",
              width=50,
              notifier = function() 
                vb.views['cf.mst.fader'].value = 1
              end
            }
            
          }
          
        },
        vb:row
        {
        width=400,
          vb:button { 
            text= 'Ignore',
            id = 'ignore_button',
            midi_mapping = "de.cie-online.DJ-Tool:Ignore",
            width=50,
            notifier = function() 
              set_ignore_mode()
            end
          }          
        }         
        
        
   }
        
  add_midi_mappings()
  -- A custom dialog is non-modal and displays a user designed
  -- layout built with the ViewBuilder.   
  dialog = renoise.app():show_custom_dialog(tool_name .. ' ' .. version, gui)  
  
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



