-- xrnx-batch-adjust-bit-depth
-- Batch adjust sample bit depth in Renoise
-- Created by hryx / Stevie Hryciw in 2014
-- License: public domain

local errs = 0
local done = 0

local vb
local view
local dialog
local process_button
local cancel_button

local bit_depth = 24
local bit_depth_items = {'8', '16', '24', '32'}
local no_upsample = true
local ok_rates = {
	[22050] = 22050,
	[44100] = 44100,
	[48000] = 48000,
	[88200] = 88200,
	[96000] = 96000
}

-- Sample adjustment

local function adjust_sample_bit_depth(samp)
	-- Old sample buffer object and verification
	local buf = samp.sample_buffer
	if not buf.has_sample_data then return end
	if not ok_rates[buf.sample_rate] then
		errs = errs + 1
		return
	end
	if no_upsample and bit_depth > buf.bit_depth then return end
	-- Copy loop info -- for some reason this is lost when writing the buffer
	local loop_mode = samp.loop_mode
	local loop_end = samp.loop_end
	-- Copy sample data from old buffer
	local data = {}
	for ch = 1, buf.number_of_channels do
		data[ch] = {}
		for frame = 1, buf.number_of_frames do
			data[ch][frame] = buf:sample_data(ch, frame)
		end
	end
	-- Prepare undo
	buf:prepare_sample_data_changes()
	-- Create a new buffer and write in old data
	buf:create_sample_data(buf.sample_rate, bit_depth, buf.number_of_channels, buf.number_of_frames)
	for ch = 1, buf.number_of_channels do
		for frame = 1, buf.number_of_frames do
			buf:set_sample_data(ch, frame, data[ch][frame])
		end
	end
	-- Finalize undo
	buf:finalize_sample_data_changes()
	-- Re-establish loop info (if changed)
	if samp.loop_end ~= loop_end then samp.loop_end = loop_end end
	if samp.loop_mode ~= loop_mode then samp.loop_mode = loop_mode end
	done = done + 1
end

local function adjust_all()
	for _, samp in ipairs(renoise.song().selected_instrument.samples) do
		adjust_sample_bit_depth(samp)
	end
	renoise.app():show_status(done .. ' samples adjusted to ' .. bit_depth .. '-bit.')
	if errs > 0 then
		renoise.app():show_warning(errs .. ' samples could not be adjusted because they use a non-standard sample rate.')
	end
	errs = 0
	done = 0
end

-- View builder

vb = renoise.ViewBuilder()

view =
	vb:column{
		margin = 6,
		vb:text{text = 'Bit depth'},
		vb:popup{
			value = 3,
			items = bit_depth_items,
			notifier = function(index)
				bit_depth = tonumber(bit_depth_items[index])
			end
		},
		vb:space{height = 6},
		vb:row{
			vb:checkbox{
				value = no_upsample,
				notifier = function(val)
					no_upsample = val
				end
			},
			vb:text{text = 'Use as maximum (don\'t upsample)'}
		}
	}

local function show_dialog()
	renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
	local btn = renoise.app():show_custom_prompt('Batch adjust bit depth', view, {'Process', 'Cancel'})
	if btn == 'Process' then
		adjust_all()
	end
end

-- Tool menu entry and key bindings

renoise.tool():add_menu_entry{
	name = "Main Menu:Tools:Batch adjust bit depth...",
	invoke = show_dialog
}

renoise.tool():add_keybinding{
	name = "Sample Editor:Edit:Batch adjust bit depth",
	invoke = function(repeated)
		if not repeated then show_dialog() end
	end
}
