-- Transient BPM Detector Tool for Renoise
-- Requires API Version 6.1

-- Declare global variables
vb = nil -- renoise.ViewBuilder
dialog = nil -- renoise.Dialog
beats_in_sample = 4 -- number
use_beatsync_refinement = false -- boolean
beatsync_override = false
transients = nil -- table
buffer = nil -- renoise.SampleBuffer
num_frames = nil -- number
ssample_rate = nil -- number
min_spacing = nil -- number
flux_values = nil -- table
energy_threshold = 0.52 -- number, for high-energy transient filtering

renoise.tool():add_menu_entry {
    name = "Sample Editor:Detect Transient BPM",
    invoke = function()
        show_transient_bpm_dialog()
    end
}

renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:Detect Transient BPM",
    invoke = function()
        show_transient_bpm_dialog()
    end
}

function show_transient_bpm_dialog()
    if dialog and dialog.visible then
        dialog:close()
        dialog = nil
    end
	local sample = renoise.song().selected_sample
    buffer = sample and sample.sample_buffer
    if buffer and buffer.has_sample_data then
        ssample_rate = buffer.sample_rate or 44100
    end
	 
    vb = renoise.ViewBuilder()

    dialog = renoise.app():show_custom_dialog(
        "Transient BPM Detector",
        vb:column {
            margin = 10,
            spacing = 8,
            vb:row {
			    vb:checkbox {
                    value = beatsync_override,
                    notifier = function(val)
                        beatsync_override = val
                    end
                },
                vb:text { text = "Beats in Sample:" },
                vb:valuebox {
				id='VBbeats_in_sample',
                    width = 80,
                    value = beats_in_sample,
                    min = 1,
                    max = 64,
                    tostring = function(val)
                        return string.format("%02d", val)
                    end,
                    tonumber = function(str)
                        return tonumber(str)
                    end,
                    notifier = function(val)
                        beats_in_sample = val
                    end
                }
            },
            vb:row {
                vb:text { text = "Energy Threshold:" },
                vb:valuebox {
					id = "VBenergy_threshold",
                    width = 80,
                    value = energy_threshold,
                    steps = {0.01, 0.1},
                    min = 0.1,
                    max = 1.0,
                    tostring = function(val)
                        return string.format("%.2f", val)
                    end,
                    tonumber = function(str)
                        return tonumber(str)
                    end,
                    notifier = function(val)
                        energy_threshold = val
                    end
                },
                vb:popup {
  id = "energy_preset",
  width = 170,
  items = {"Simple beats (one hit each frame)", "Complex beats", "Crowded beats", "Fast crowded beats"},
  value = 2, -- Default to Medium (52%)
  notifier = function(val)
    local thresholds = {0.3, 0.52, 0.88, 0.88}
    local spacings_ms = {155, 150, 100, 30}
    energy_threshold = thresholds[val]   

    min_spacing = (spacings_ms[val] / 1000) * (ssample_rate or 44100)

    local vb_view = vb.views["VBenergy_threshold"]
    if vb_view then vb_view.value = energy_threshold end

    local spacing_view = vb.views["VBmin_spacing"]
    if spacing_view then spacing_view.value = spacings_ms[val] end
  end
}
            },
            vb:row {
                vb:text { text = "Min Spacing (ms):" },
                vb:valuebox {
                    id = "VBmin_spacing",
                    width = 80,
                    value = (min_spacing or (ssample_rate * 0.150)) * 1000 / ssample_rate, -- Convert to ms
                    steps = {1, 10},
                    min = 10,
                    max = 200,
                    tostring = function(val)
                        return string.format("%d", val)
                    end,
                    tonumber = function(str)
                        return tonumber(str)
                    end,
                    notifier = function(val)
                        min_spacing = (val / 1000) * ssample_rate -- Convert ms to frames
                    end
                }
            },
            vb:button {
                text = "Detect BPM",
                width = 100,
                notifier = function()
                    initialize_analysis()
                end
            },
			vb:row {
				vb:text { text = "Results:" }
			},
			vb:horizontal_aligner {
				mode = "left",
				vb:multiline_textfield {
					id = "bpm_results",
					width = 400,
					height = 160,
					font = "mono",
					active = false,
					text = "Click 'Detect BPM' to calculate..."
				}
			}
        }
    )
end

function initialize_analysis()
    local sample = renoise.song().selected_sample
    buffer = sample and sample.sample_buffer

    if not (buffer and buffer.has_sample_data) then
        renoise.app():show_error("No sample with valid data selected.")
        return
    end
	vb.views["bpm_results"].text=''
    transients = {}
    flux_values = {}
    num_frames = buffer.number_of_frames
    ssample_rate = buffer.sample_rate
	 	
    min_spacing = (vb.views["VBmin_spacing"].value / 1000) * ssample_rate
	print_status(string.format("Initialized min_spacing: %.2f frames (from %d ms)", min_spacing, vb.views["VBmin_spacing"].value))
    renoise.app():show_status("Started transient analysis...")
    transients, flux_values = detect_transients(buffer)
    finalize_analysis()
end

function print_status(msg)
  if vb and vb.views["bpm_results"] then
    vb.views["bpm_results"].text = vb.views["bpm_results"].text..'\r\n'..msg
	vb.views["bpm_results"]:scroll_to_last_line()
  else
    print(msg)
  end
end

function detect_transients(sample_buffer)
    local transients = {}
    local frames = sample_buffer.number_of_frames
    local sr = sample_buffer.sample_rate
    local channel = 1
    local window_size = math.floor(sr * 0.02) -- 20ms window for high-BPM sensitivity
    local hop_size = math.floor(window_size / 2)
    local flux_values = {}
    local prev_sum = 0
    local energies = {}

    -- Compute spectral flux and energy
    for pos = 1, frames - window_size, hop_size do
        local sum = 0
        local energy = 0
        for i = 0, window_size - 1 do
            local val = math.abs(sample_buffer:sample_data(channel, pos + i))
            sum = sum + val
            energy = energy + (val ^ 2)
        end
        local flux = math.max(0, sum - prev_sum)
        flux_values[#flux_values + 1] = { pos = pos, flux = flux, energy = energy }
        prev_sum = sum
        energies[#energies + 1] = energy
    end

    -- Find maximum energy for thresholding
    local max_energy = 0
    for _, e in ipairs(energies) do
        if e > max_energy then max_energy = e end
    end
    local local_energy_threshold = max_energy * energy_threshold

    -- Adaptive flux thresholding based on median
    local fluxes = {}
    for _, v in ipairs(flux_values) do
        fluxes[#fluxes + 1] = v.flux
    end
    table.sort(fluxes)
    local median_flux = fluxes[math.floor(#fluxes / 2)]
    local flux_threshold = median_flux * 1.3

    -- Detect transients with high energy and flux, respecting min_spacing
    local last_transient = -min_spacing
    for i, v in ipairs(flux_values) do
        local spacing = v.pos - last_transient
        if v.flux > flux_threshold and v.energy > local_energy_threshold and spacing > min_spacing then
            transients[#transients + 1] = v.pos
            last_transient = v.pos
        else
        end
    end

    return transients, flux_values
end

function estimate_beats_in_sample(transients, sample_duration_secs, sample_rate)
    local intervals = {}
    for i = 2, #transients do
        intervals[#intervals + 1] = transients[i] - transients[i - 1]
    end

    local interval_counts = {}
    local interval_resolution = math.floor(sample_rate * 0.01)
    for _, interval in ipairs(intervals) do
        local key = math.floor(interval / interval_resolution) * interval_resolution
        interval_counts[key] = (interval_counts[key] or 0) + 1
    end

    local max_count = 0
    local beat_interval = 0
    for interval, count in pairs(interval_counts) do
        if count > max_count then
            max_count = count
            beat_interval = interval
        end
    end

    if beat_interval == 0 then
        return beats_in_sample
    end

    local beat_duration_secs = beat_interval / sample_rate
    local estimated_beats = sample_duration_secs / beat_duration_secs

    local possible_beats = {2, 4, 8, 16, 32}
    local best_beat_count = beats_in_sample
    local min_error = math.huge
    for _, n in ipairs(possible_beats) do
        local error = math.abs(n - estimated_beats)
        if error < min_error then
            min_error = error
            best_beat_count = n
        end
    end

    -- Cap beats_in_sample to avoid extreme values
    if best_beat_count > 16 then
        best_beat_count = beats_in_sample -- Revert to user input if too high
    end

    return best_beat_count
end

function debug_transients(transients, flux_values)
    for i, pos in ipairs(transients) do
        for _, v in ipairs(flux_values) do
            if v.pos == pos then
                print_status(string.format("Transient %d at %.3f seconds, energy: %.2f", i, pos / ssample_rate, v.energy))
                break
            end
        end
    end
end

function finalize_analysis()
    renoise.app():show_status("Counting transients...")

    if #transients < 2 then
        renoise.app():show_status("Not enough transients to estimate BPM.")
        return
    end

    local sample = renoise.song().selected_sample
    buffer = sample and sample.sample_buffer
    local sample_duration_secs = buffer.number_of_frames / ssample_rate

    print_status(string.format("Sample duration: %.4f seconds", sample_duration_secs))
    debug_transients(transients, flux_values)

    local estimated_beats = #transients --estimate_beats_in_sample(transients, sample_duration_secs, ssample_rate)
    if estimated_beats ~= beats_in_sample and beatsync_override == false then
        beats_in_sample = estimated_beats
        print_status(string.format("Estimated %d beats in sample", beats_in_sample))
        renoise.app():show_status(string.format("Estimated %d beats in sample", beats_in_sample))
    else
        beats_in_sample = vb.views['VBbeats_in_sample'].value
    end

    -- Calculate initial BPM
    local bpm = (beats_in_sample * 60) / sample_duration_secs
    print_status(string.format("Detected BPM for %.2f beats: %.2f", beats_in_sample, bpm))

    -- Constrain BPM to a reasonable range (temporarily allow >200 for debugging)
    if bpm < 30 then
        bpm = bpm * 4 -- Handle quarter-time
    elseif bpm < 60 then
        bpm = bpm * 2 -- Handle half-time
    elseif bpm > 400 then
        bpm = bpm / 4 -- Handle quadruple-time
    elseif bpm > 200 then
        bpm = bpm / 2 -- Handle double-time
    end
    local best_bpm = bpm

    -- Optional: Calculate nearest plausible BPM for reference
    local plausible_bpms = {60, 65, 70, 75, 80, 85, 90, 95, 100, 105, 110, 115, 120, 125, 128, 130, 135, 140, 145, 150, 155, 160, 165, 170, 175, 180, 185, 190, 195, 200}
    local min_diff = math.huge
    local nearest_plausible = bpm
    for _, p_bpm in ipairs(plausible_bpms) do
        local diff = math.abs(bpm - p_bpm)
        if diff < min_diff then
            min_diff = diff
            nearest_plausible = p_bpm
        end
    end

    -- Output the detected BPM with the nearest plausible value as a note
    renoise.app():show_status(string.format("Detected BPM: %.2f (Nearest plausible: %.0f, %d transients, %d beats)", bpm, nearest_plausible, #transients, beats_in_sample))
    beats_in_sample = vb.views['VBbeats_in_sample'].value
end