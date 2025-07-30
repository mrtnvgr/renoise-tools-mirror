-- constants --

MINIMAL_LENGTH = 0.04
BIN = {
	WINDOWS = "bin/win/Akaizer.exe",
	LINUX = "bin/linux/Akaizer",
	MACINTOSH = "bin/osx/Akaizer"
}

-- init --

renoise.tool():add_menu_entry {
	name = "Sample Editor:Process:Akaizer...",
	invoke = function()
		local length = get_sample_length()

		if length <= MINIMAL_LENGTH then
			renoise.app():show_error("The sample is too short! Minimal length is 40 ms.")
		else
			show_dialog()
		end
	end
}

if(os.platform() == "LINUX" or os.platform() == "MACINTOSH") then
	io.chmod(renoise.tool().bundle_path..BIN[os.platform()], 755)
end

-- helpers --

function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function remove_file_extension(filename)
	local found, len, remainder = filename:find("^(.*)%.[^%.]*$")

	if found then
		return remainder
	else
		return filename
	end
end

function parse_path(path)
	local dir, name, ext = path:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
	name = remove_file_extension(name)

	return dir, name
end

function get_sample_length()
	local sample = renoise.song().selected_sample.sample_buffer

	local sample_rate = sample.sample_rate
	local frames = sample.number_of_frames

	return frames / sample_rate
end

function get_line_length()
	local bpm = renoise.song().transport.bpm
	local lpb = renoise.song().transport.lpb

	return 60 / bpm / lpb
end

function get_line_factor()
	local line_length = get_line_length()
	local sample_length = get_sample_length()

	return line_length / sample_length * 100
end

-- processing --

function process_sample(time_factor, cycle_length, transpose, is_classic)
	if time_factor == 100 and transpose == 0 then
		renoise.app():show_message("Sample wasn't processed because you didn't change both time factor and transpose.")
	else
		local tmp_path = os.tmpname("wav")
		local tmp_dir, tmp_name = parse_path(tmp_path)

		local output = string.format("%s-%s%%_%d_%s%d_%s.wav",
			tmp_name,
			tostring(time_factor),
			cycle_length,
			transpose > 0 and "+" or "",
			transpose,
			is_classic and "C" or "R"
		)

		local exe = string.format("%s%s %s %s %u %d%s", 
			renoise.tool().bundle_path,
			BIN[os.platform()],
			tmp_path,
			tostring(time_factor):gsub("%.", ","),
			cycle_length,
			transpose,
			is_classic and " -c" or ""
		)

		renoise.song().selected_sample.sample_buffer:save_as(tmp_path, "wav")
		os.execute(exe)
		renoise.song().selected_sample.sample_buffer:load_from(tmp_dir..output)
		
		renoise.app():show_message("Successfully processed!")
	end
end

-- dialogs --

function show_dialog()
	local vb = renoise.ViewBuilder()

	local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
	local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING	

	-- view elements --

	local no_sync_box = vb:valuebox {
		width = 120,
		min = 25,
		max = 2000,
		value = 100
	}

	local cycle_box = vb:valuebox {
		width = 120,
		min = 20,
		max = 2000,
		value = 1000
	}

	local transpose_box = vb:valuebox {
		width = 120,
		min = -24,
		max = 24,
		value = 0
	}

	local is_classic_box = vb:checkbox {
		value = false
	}

	local time_row_percent = vb:text {
		text = "%",
		width = 80
	}

	-- rows --

	local time_row = vb:row {
		vb:text {
			text = "Time factor",
			width = 80
		},
		no_sync_box,
		time_row_percent
	}

	local cycle_row = vb:row {
		vb:text {
			text = "Cycle length",
			width = 80
		},
		cycle_box,
		vb:text {
			text = "samples",
			width = 80
		}
	}

	local transpose_row = vb:row {
		vb:text {
			text = "Transpose",
			width = 80
		},
		transpose_box,
		vb:text {
			text = "semitones",
			width = 80
		}
	}

	local is_classic_row = vb:row {
		is_classic_box,
		vb:text {
			text = 'Enable "classic" cyclic algorithm'
		}
	}

	-- prompt --

	local prompt = renoise.app():show_custom_prompt(
		"Akaizer",

		vb:column {
			margin = DIALOG_MARGIN,
			spacing = CONTENT_SPACING,

			time_row,
			cycle_row,
			transpose_row,
			is_classic_row
		},

		{ "Process", "Cancel" }
	)

	local time_factor = no_sync_box.value

	if prompt == "Process" then 
		process_sample(
			round(time_factor, 4), 
			cycle_box.value, 
			transpose_box.value, 
			is_classic_box.value
		)
	end
end
