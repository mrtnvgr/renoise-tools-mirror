--[[============================================================================
Chop Sample

Author: Florian Krause <siebenhundertzehn@gmail.com>
Version: 0.2
============================================================================]]--

-- Register the tool
renoise.tool():add_menu_entry{
  name = 'Sample Editor:Slices:Chop Sample',
  invoke = function() gui() end
}

-- Add key bindings
renoise.tool():add_keybinding{
  name = 'Sample Editor:Slices:Chop Sample',
  invoke = function() gui() end
}

-- The actual work
local function chop(n_slices)
    local sample = renoise.song().selected_instrument.samples[1]
    
    while #sample.slice_markers > 0 do
        sample:delete_slice_marker(sample.slice_markers[1])
    end  
    for i = 0, n_slices - 1, 1 do
      sample:insert_slice_marker(1 + math.floor(i * 
      sample.sample_buffer.number_of_frames / n_slices))
    end
end

-- Not working stuff, maybe in the future, complain at devs not me
local note_names = {}
note_names[0] = 'C-0'
note_names[1] = 'C#0'
note_names[2] = 'D-0'
note_names[3] = 'D#0'
note_names[4] = 'E-0'
note_names[5] = 'F-0'
note_names[6] = 'F#0'
note_names[7] = 'G-0'
note_names[8] = 'G#0'
note_names[9] = 'A-0'
note_names[10] = 'A#0'
note_names[11] = 'B-0'
note_names[12] = 'C-1'
note_names[13] = 'C#1'
note_names[14] = 'D-1'
note_names[15] = 'D#1'
note_names[16] = 'E-1'
note_names[17] = 'F-1'
note_names[18] = 'F#1'
note_names[19] = 'G-1'
note_names[20] = 'G#1'
note_names[21] = 'A-1'
note_names[22] = 'A#1'
note_names[23] = 'B-1'
note_names[24] = 'C-2'
note_names[25] = 'C#2'
note_names[26] = 'D-2'
note_names[27] = 'D#2'
note_names[28] = 'E-2'
note_names[29] = 'F-2'
note_names[30] = 'F#2'
note_names[31] = 'G-2'
note_names[32] = 'G#2'
note_names[33] = 'A-2'
note_names[34] = 'A#2'
note_names[35] = 'B-2'
note_names[36] = 'C-3'
note_names[37] = 'C#3'
note_names[38] = 'D-3'
note_names[39] = 'D#3'
note_names[40] = 'E-3'
note_names[41] = 'F-3'
note_names[42] = 'F#3'
note_names[43] = 'G-3'
note_names[44] = 'G#3'
note_names[45] = 'A-3'
note_names[46] = 'A#3'
note_names[47] = 'B-3'
note_names[48] = 'C-4'
note_names[49] = 'C#4'
note_names[50] = 'D-4'
note_names[51] = 'D#4'
note_names[52] = 'E-4'
note_names[53] = 'F-4'
note_names[54] = 'F#4'
note_names[55] = 'G-4'
note_names[56] = 'G#4'
note_names[57] = 'A-4'
note_names[58] = 'A#4'
note_names[59] = 'B-4'
note_names[60] = 'C-5'
note_names[61] = 'C#5'
note_names[62] = 'D-5'
note_names[63] = 'D#5'
note_names[64] = 'E-5'
note_names[65] = 'F-5'
note_names[66] = 'F#5'
note_names[67] = 'G-5'
note_names[68] = 'G#5'
note_names[69] = 'A-5'
note_names[70] = 'A#5'
note_names[71] = 'B-5'
note_names[72] = 'C-6'
note_names[73] = 'C#6'
note_names[74] = 'D-6'
note_names[75] = 'D#6'
note_names[76] = 'E-6'
note_names[77] = 'F-6'
note_names[78] = 'F#6'
note_names[79] = 'G-6'
note_names[80] = 'G#6'
note_names[81] = 'A-6'
note_names[82] = 'A#6'
note_names[83] = 'B-6'
note_names[84] = 'C-7'
note_names[85] = 'C#7'
note_names[86] = 'D-7'
note_names[87] = 'D#7'
note_names[88] = 'E-7'
note_names[89] = 'F-7'
note_names[90] = 'F#7'
note_names[91] = 'G-7'
note_names[92] = 'G#7'
note_names[93] = 'A-7'
note_names[94] = 'A#7'
note_names[95] = 'B-7'
note_names[96] = 'C-8'
note_names[97] = 'C#8'
note_names[98] = 'D-8'
note_names[99] = 'D#8'
note_names[100] = 'E-8'
note_names[101] = 'F-8'
note_names[102] = 'F#8'
note_names[103] = 'G-8'
note_names[104] = 'G#8'
note_names[105] = 'A-8'
note_names[106] = 'A#8'
note_names[107] = 'B-8'
note_names[108] = 'C-9'
note_names[109] = 'C#9'
note_names[110] = 'D-9'
note_names[111] = 'D#9'
note_names[112] = 'E-9'
note_names[113] = 'F-9'
note_names[114] = 'F#9'
note_names[115] = 'G-9'
note_names[116] = 'G#9'
note_names[117] = 'A-9'
note_names[118] = 'A#9'
note_names[119] = 'B-9'

function tostring(number)
  return note_names[number]
end

function tonumber(string)
  key = note_names.find(string)
  return note_names[key]
end

-- Create GUI
function gui()
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
  local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local dialog
  local vb = renoise.ViewBuilder()
    
  local dialog_content = vb:horizontal_aligner{
    margin=DIALOG_MARGIN,
    spacing=DIALOG_SPACING,
    mode='center',
    
    vb:column{
      vb:horizontal_aligner{
        spacing = CONTROL_SPACING,
        mode='justify',
        vb:text{text="Number of Slices"},
        vb:valuebox{id='n_slices', value=16}
      },
      --vb:horizontal_aligner{
        --spacing = CONTROL_SPACING,
        --mode='justify',
        --vb:text{text="First Slice"},
        --vb:valuebox{id='first_slice', tostring=tostring, tonumber=tonumber, value=36}
      --},
      vb:space{ height=DIALOG_SPACING },
      vb:horizontal_aligner{
        mode = 'center',
        vb:button{
          id='slice_button',
          height=DIALOG_BUTTON_HEIGHT,
          width=80,
          text='Chop',  
          notifier=function()
            dialog:close()
            chop(vb.views.n_slices.value)
          end
          },
        }
      }
    }
    
    local function keyhandler_func(dialog, key)
      if (key.modifiers == '' and key.name == 'return') then
        dialog:close()
        chop(vb.views.n_slices.value)
      elseif (key.modifiers == '' and key.name == 'esc') then
        dialog:close()
      end
    end
    
    dialog = renoise.app():show_custom_dialog('Chop Sample', 
                                              dialog_content, keyhandler_func)
 end
