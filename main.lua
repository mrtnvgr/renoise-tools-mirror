renoise.tool():add_menu_entry {
	name = "Main Menu:Tools:Combine Instruments",
	invoke = function() gui() end
}

renoise.tool():add_menu_entry {
	name = "Instrument Box:Combine Instruments",
	invoke = function() gui() end
}

renoise.tool():add_keybinding {
	name = "Global:Tools:Combine Instruments",
	invoke = function() gui() end
}

function generate_instrument(first, last)
	if first >= last then return end
	local newinst = renoise.song():insert_instrument_at(last+1)
	newinst.name = "Combined Instrument"
	for i = first, last do
  		for j, sample in ipairs(renoise.song().instruments[i].samples) do
    		if sample.sample_buffer.has_sample_data then
      			local dest_sample = newinst:insert_sample_at(#newinst.samples+1)
      			dest_sample.name = sample.name
           
      			local ch = sample.sample_buffer.number_of_channels
      			local fr = sample.sample_buffer.number_of_frames
      			local bd = sample.sample_buffer.bit_depth
      			local sr = sample.sample_buffer.sample_rate
      
      			dest_sample.sample_buffer:create_sample_data(sr,bd,ch,fr)
      			for c = 1, ch do
        			for f = 1, fr do
          				local sample_data = sample.sample_buffer:sample_data(c,f)
          				dest_sample.sample_buffer:set_sample_data(c,f,sample_data)
        			end
      			end
    		end

  		end
	end
end

function gui()
	local dialog
  	local vb = renoise.ViewBuilder()
  	local dialog_title = "Combine Instruments"
  	local dialog_content = vb:column {
    	vb:horizontal_aligner {
      		mode='justify',
      		vb:text{text = "Select the range: "},
      		vb:valuebox{
        		id = "start",
        		min = 0,
        		max = #renoise.song().instruments - 1,
        		tostring = function(n)
        	  		return string.upper(string.format("%02x", n))
        		end,
        		tonumber = function(n)
          			return tonumber(n,16)
        		end        
      		},
      		vb:valuebox{
        		id = "finish",
        		min = 0,
        		max = #renoise.song().instruments - 1,
        		tostring = function(n)
          			return string.upper(string.format("%02x", n))
        		end,
        		tonumber = function(n)
          			return tonumber(n,16)
        		end        
      		},
    	},
    	vb:space{height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING},
    	vb:horizontal_aligner {
      		mode = "center",
      		vb:button{
          		text='Combine!',  
          		notifier=function()
            		dialog:close()
            		generate_instrument(vb.views.start.value + 1, vb.views.finish.value + 1)
          		end
      		}
    	}   
	}
 	dialog = renoise.app():show_custom_dialog(dialog_title, dialog_content)
end