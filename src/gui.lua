---@diagnostic disable: lowercase-global, undefined-global

EASING_FUNCTIONS = {
    "linear",
    "inQuad",
    "outQuad",
    "inOutQuad",
    "outInQuad",
    "inCubic",
    "outCubic",
    "inOutCubic",
    "outInCubic",
    "inQuart",
    "outQuart",
    "inOutQuart",
    "outInQuart",
    "inQuint",
    "outQuint",
    "inOutQuint",
    "outInQuint",
    "inSine",
    "outSine",
    "inOutSine",
    "outInSine",
    "inExpo",
    "outExpo",
    "inOutExpo",
    "outInExpo",
    "inCirc",
    "outCirc",
    "inOutCirc",
    "outInCirc",
    "inBounce",
    "outBounce",
    "inOutBounce",
    "outInBounce",
    "inElastic",   -- tady se mění parametry
    "outElastic",
    "inOutElastic",
    "outInElastic",
    "inBack",      -- mení se parametry
    "outBack",
    "inOutBack",
    "outInBack",
	"none",
}

FILTERS = {
	"LowPass filter",
	"HighPass filter",
	"BandPass filter",
	"Notch filter",
	"AllPass filter",
	"PeakEQ filter",
	"LowShelf filter",
	"HighShelf filter",
	"None"
}

VALUEFIELD_WIDTH = 60
TEXT_WIDTH = 90
SLIDER_WIDTH = 150
POPUP_WIDTH = 210
SPACING = 4
MARGIN = 4

function check_gui_visibility()
	local switch = vbs.drum_switch.value
	if switch == 1 then -- kick drum gui
		
		vbs.kick_gui.visible = true
		vbs.snare_gui.visible = false
		vbs.hihat_gui.visible = false
		vbs.cymbal_gui.visible = false
		vbs.claps_gui.visible = false
		vbs.karplus_gui.visible = false
		vbs.glocken_gui.visible = false
		vbs.glitcher_gui.visible = false

	elseif switch == 2 then -- snare drum gui
		vbs.kick_gui.visible = false
		vbs.snare_gui.visible = true
		vbs.hihat_gui.visible = false
		vbs.cymbal_gui.visible = false
		vbs.claps_gui.visible = false
		vbs.karplus_gui.visible = false
		vbs.glocken_gui.visible = false
		vbs.glitcher_gui.visible = false
	
	elseif switch == 3 then -- hihat gui
		vbs.kick_gui.visible = false
		vbs.snare_gui.visible = false
		vbs.hihat_gui.visible = true
		vbs.cymbal_gui.visible = false
		vbs.claps_gui.visible = false
		vbs.karplus_gui.visible = false
		vbs.glocken_gui.visible = false
		vbs.glitcher_gui.visible = false
	
	elseif switch == 4 then -- cymbal gui
		vbs.kick_gui.visible = false
		vbs.snare_gui.visible = false
		vbs.hihat_gui.visible = false
		vbs.cymbal_gui.visible = true
		vbs.claps_gui.visible = false
		vbs.karplus_gui.visible = false
		vbs.glocken_gui.visible = false
		vbs.glitcher_gui.visible = false

	elseif switch == 5 then -- claps gui
		vbs.kick_gui.visible = false
		vbs.snare_gui.visible = false
		vbs.hihat_gui.visible = false
		vbs.cymbal_gui.visible = false
		vbs.claps_gui.visible = true
		vbs.karplus_gui.visible = false
		vbs.glocken_gui.visible = false
		vbs.glitcher_gui.visible = false

	elseif switch == 6 then -- karplus gui
		vbs.kick_gui.visible = false
		vbs.snare_gui.visible = false
		vbs.hihat_gui.visible = false
		vbs.cymbal_gui.visible = false
		vbs.claps_gui.visible = false
		vbs.karplus_gui.visible = true
		vbs.glocken_gui.visible = false
		vbs.glitcher_gui.visible = false

	elseif switch == 7 then -- glockenSpiel gui
		vbs.kick_gui.visible = false
		vbs.snare_gui.visible = false
		vbs.hihat_gui.visible = false
		vbs.cymbal_gui.visible = false
		vbs.claps_gui.visible = false
		vbs.karplus_gui.visible = false
		vbs.glocken_gui.visible = true
		vbs.glitcher_gui.visible = false

	elseif switch == 8 then -- glitcher gui
		vbs.kick_gui.visible = false
		vbs.snare_gui.visible = false
		vbs.hihat_gui.visible = false
		vbs.cymbal_gui.visible = false
		vbs.claps_gui.visible = false
		vbs.karplus_gui.visible = false
		vbs.glocken_gui.visible = false
		vbs.glitcher_gui.visible = true

	end

	local value = vbs.envelope.value
		
	if value == 34 or value == 35 or value == 36 or value == 37 then
		vbs.elastic_gui.visible=true
		vbs.back_gui.visible=false
		
	elseif value == 38 or value == 39 or value == 40 or value == 41 then
		vbs.elastic_gui.visible=false
		vbs.back_gui.visible=true
		
	else
		vbs.elastic_gui.visible=false
		vbs.back_gui.visible=false
	end

	if vbs.karplus_filter1_selector.value == #FILTERS then
		vbs.karplus_filter1_gui.visible=false
	else
		vbs.karplus_filter1_gui.visible=true
	end

	if vbs.karplus_filter2_selector.value == #FILTERS then
		vbs.karplus_filter2_gui.visible=false
	else
		vbs.karplus_filter2_gui.visible=true
	end

	if vbs.karplus_filter3_selector.value == #FILTERS then
		vbs.karplus_filter3_gui.visible=false
	else
		vbs.karplus_filter3_gui.visible=true
	end

	if vbs.hihat_type_switch.value == 1 then
		vbs.hihat1_gui.visible=true
		vbs.hihat2_gui.visible=false
	elseif vbs.hihat_type_switch.value == 2 then
		vbs.hihat1_gui.visible=false
		vbs.hihat2_gui.visible=true
	end

	if vbs.kick_wave_selector.value == 3 then -- pulse wave selected
		vbs.kick_wave_parameter.visible=true
	else
		vbs.kick_wave_parameter.visible=false
	end
end


function make_row(text, idx, min, max, default, steps, render)
	local rndr = render or true
	local gui = vb:horizontal_aligner{
		mode="left",
		vb:text{text=text, width=TEXT_WIDTH},
		vb:slider{
			id=idx.."_slider",
			width=SLIDER_WIDTH,
			min=min,
			max=max,
			value=default,
			steps=steps,
			notifier=function(value)
				vbs[idx.."_field"].value = value
				if rndr == true then
					render_sample()
				end
			end
		},
		vb:valuefield{
			id=idx.."_field",
			width=VALUEFIELD_WIDTH,
			min=min,
			max=max,
			value=default,
			notifier=function(value)
				vbs[idx.."_slider"].value = value
			end
		},
	}
	return gui
end


-----------------------------------------------------------------------------------------------------
-- GUI FOR ENVELOPES                                                                                -
-----------------------------------------------------------------------------------------------------

make_back_gui = vb:column{
	id="back_gui",
	style="invisible",
	make_row("Parameter", "parameter", 0.1, 20, 1, {0.01, 0.1}),
}

make_elastic_gui = vb:column{
	id="elastic_gui",
	style="invisible",
	make_row("Amplitude", "amplitude", 0.1, 20, 1, {0.01, 0.1}),
	make_row("Period", "period", 0.01, 1.0, 0.5, {0.01, 0.1}),
}


-----------------------------------------------------------------------------------------------------
-- KICK DRUM GUI                                                                                    -
-----------------------------------------------------------------------------------------------------

kick_gui = vb:column{
	id="kick_gui",
	style="invisible",
	spacing=SPACING,
	margin=0,
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Kicks & Blips ~",
				style="strong",
				font="bold",
			},
		},
		make_row("Duration", "kick_duration", 0.001, 2.0, 0.2, {0.01, 0.1}),
		make_row("Periods", "kick_periods", 1.0, 9.0, 2, {1, 2}),
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Kick wave", width=TEXT_WIDTH},
			vb:popup{
				id="kick_wave_selector",
				width=POPUP_WIDTH,
				items={"Cosine", "Saw", "Pulse"},
				value=1,
				notifier=function(value)
					check_gui_visibility()
					render_sample()
				end
			},
		},
		vb:column{
			id="kick_wave_parameter",
			style="invisible",
			spacing=SPACING,
			margin=0,
			make_row("Pulse len", "kick_pulse_len", 0.01, 0.99, 0.5, {0.01, 0.1}),
		},
	},
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Kick drum filter ~",
				style="strong",
				font="bold",
			},
		},
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Filter", width=TEXT_WIDTH},
			vb:popup{
				id="kick_filter_selector",
				width=POPUP_WIDTH,
				items=FILTERS,
				value=1,
				notifier=function(value)
					check_gui_visibility()
					render_sample()
				end
			},
		},
		make_row("Filter", "kick_filter", 100, 6000, 1000, {0.1, 1}),
		make_row("Filter Q", "kick_filter_Q", 0.01, 20.0, 0.8, {0.01, 0.1}),
	},
}


-----------------------------------------------------------------------------------------------------
-- SNARE DRUM GUI                                                                                   -
-----------------------------------------------------------------------------------------------------

snare_gui = vb:column{
	id="snare_gui",
	style="invisible",
	spacing=SPACING,
	margin=0,
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Snare drum generator ~",
				style="strong",
				font="bold",
			},
		},
		make_row("Duration", "snare_duration", 0.001, 2.0, 0.5, {0.01, 0.1}),
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Noise", width=TEXT_WIDTH},
			vb:popup{
				id="snare_noise_select",
				width=POPUP_WIDTH,
				items={"White noise", "Pink noise", "Brownian noise"},
				value=1,
				notifier=function(value)
					render_sample()
				end
			},
		},
		make_row("Noise volume", "snare_noise_volume", 0.0, 5.0, 0.5, {0.01, 0.1}),
		make_row("Osc frequency", "snare_osc_frequency", 20, 400, 200, {1, 2}),
		make_row("Osc volume", "snare_osc_volume", 0.0, 1.0, 0.5, {0.01, 0.1}),
	},
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Snare drum filters ~",
				style="strong",
				font="bold",
			},
		},
		make_row("HighPass", "snare_highpass", 10, 10000, 3000, {1, 2}),
		make_row("HighPass Q", "snare_highpass_Q", 0.1, 20, 1, {0.01, 0.1}),
		make_row("BandPass", "snare_bandpass", 10, 10000, 5000, {1, 2}),
		make_row("BandPass Q", "snare_bandpass_Q", 0.1, 20, 1, {0.01, 0.1}),
		make_row("LowPass", "snare_lowpass", 10, 10000, 4000, {0.01, 0.1}),
		make_row("LowPass Q", "snare_lowpass_Q", 0.1, 20, 1, {0.01, 0.1}),
	},
}


-----------------------------------------------------------------------------------------------------
-- HIHAT GUI
-----------------------------------------------------------------------------------------------------

hihat_gui = vb:column{
	id="hihat_gui",
	style="invisible",
	spacing=SPACING,
	margin=0,
	vb:horizontal_aligner{
		mode="distribute",
		vb:switch{
			id="hihat_type_switch",
			width=200,
			items={"Oldschool", "Metalic"},
			value=1,
			notifier=function(value)
				check_gui_visibility()
			end
		},
	},
	 vb:column{
		id="hihat1_gui",
		style="invisible",
		spacing=SPACING,
		margin=0,
		vb:column{
			style="group",
			spacing=SPACING,
			margin=MARGIN,
			vb:horizontal_aligner{
				mode="distribute",
				vb:text{
					text="~ HiHat generator ~",
					style="strong",
					font="bold",
				},
			},
			make_row("Duration", "hihat1_duration", 0.001, 2.0, 0.2, {0.01, 0.1}),
			vb:horizontal_aligner{
				mode="left",
				vb:text{text="Noise", width=TEXT_WIDTH},
				vb:popup{
					id="hihat1_noise_select",
					width=POPUP_WIDTH,
					items={"White noise", "Pink noise", "Brownian noise"},
					value=1,
					notifier=function(value)
						render_sample()
					end
				},
			},
			make_row("Noise mix", "hihat1_noisemix", 0.1, 2.0, 0.5, {0.01, 0.1}),
		},
		vb:column{
			style="group",
			spacing=SPACING,
			margin=MARGIN,
			vb:horizontal_aligner{
				mode="distribute",
				vb:text{
					text="~ Phasor frequencies ~",
					style="strong",
					font="bold",
				},
			},
			make_row("Frequency 1", "hihat1_phasor1_freq", 0.1, 2000, 350, {0.1, 1}),
			make_row("Frequency 2", "hihat1_phasor2_freq", 0.1, 2000, 800, {0.1, 1}),
			make_row("Phasors vol", "hihat1_phasors_volume", 0.0, 2.0, 0.5, {0.01, 0.1}),
		},
		vb:column{
			style="group",
			spacing=SPACING,
			margin=MARGIN,
			vb:horizontal_aligner{
				mode="distribute",
				vb:text{
					text="~ HiHat filters ~",
					style="strong",
					font="bold",
				},
			},
			make_row("Filter 1", "hihat1_filter1", 10.0, 10000, 8000, {0.1, 1}),
			make_row("Filter 1 Q", "hihat1_filter1_Q", 0.1, 20, 16, {0.01, 0.1}),
			make_row("Filter 2", "hihat1_filter2", 10.0, 10000, 8000, {0.1, 1}),
			make_row("Filter 2 Q", "hihat1_filter2_Q", 0.1, 20, 1, {0.01, 0.1}),
			make_row("Filter 3", "hihat1_filter3", 10.0, 10000, 8000, {0.1, 1}),
			make_row("Filter 3 Q", "hihat1_filter3_Q", 0.1, 20, 1, {0.01, 0.1}),
		},
	},
	vb:column{
		id="hihat2_gui",
		style="invisible",
		spacing=SPACING,
		margin=0,
		vb:column{
			style="group",
			spacing=SPACING,
			margin=MARGIN,
			vb:horizontal_aligner{
				mode="distribute",
				vb:text{
					text="~ HiHat generator ~",
					style="strong",
					font="bold",
				},
			},
			make_row("Duration", "hihat2_duration", 0.01, 2.0, 0.2, {0.01, 0.1}),
			make_row("Frequency", "hihat2_freq", 0.01, 2000, 350, {0.1, 1})
		},
		vb:column{
			style="group",
			spacing=SPACING,
			margin=MARGIN,
			vb:horizontal_aligner{
				mode="distribute",
				vb:text{
					text="~ HiHat filters ~",
					style="strong",
					font="bold",
				},
			},
			make_row("Filter 1 Q", "hihat2_f1_Q", 0.1, 20, 20, {0.1, 1}),
			make_row("Filter 2 Q", "hihat2_f2_Q", 0.1, 20, 1, {0.1, 1}),
			make_row("Filter 3 Q", "hihat2_f3_Q", 0.1, 20, 1, {0.1, 1}),
			make_row("Filter 4 Q", "hihat2_f4_Q", 0.1, 20, 1, {0.1, 1}),
		},
	},
}


-----------------------------------------------------------------------------------------------------
-- CYMBAL                                                                                           -
-----------------------------------------------------------------------------------------------------

cymbal_gui = vb:column{
	id="cymbal_gui",
	style="invisible",
	spacing=SPACING,
	margin=0,
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Cymbal ~",
				style="strong",
				font="bold",
			},
		},
		make_row("Duration", "cymbal_duration", 0.001, 2.0, 0.5, {0.1, 1}),
		make_row("Frequency", "cymbal_frequency", 10, 2000, 800, {1, 10}),
		make_row("Phasors vol", "cymbal_volume", 0.1, 5.0, 1.0, {0.1, 1}),
		make_row("Noise vol", "cymbal_noise_volume", 0.1, 5.0, 2.0, {0.1, 1}),
	},
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Filters ~",
				style="strong",
				font="bold",
			},
		},
		make_row("Filter 1", "cymbal_filter1", 100, 10000, 7000, {0.1, 1.0}),
		make_row("Filter 2", "cymbal_filter2", 100, 10000, 6800, {0.1, 1.0}),
		make_row("Filter 3", "cymbal_filter3", 100, 10000, 6800, {0.1, 1.0}),
		make_row("Filter 4", "cymbal_filter4", 100, 10000, 1200, {0.1, 1.0}),
	},
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Metalizer ~",
				style="strong",
				font="bold",
			},
		},
		make_row("Delay", "cymbal_delay", 1, 2000, 3, {1, 2}),
		make_row("Attenuation", "cymbal_attenuation", 0.0, 1.0, 0.5, {0.01, 0.1}),
	},
}


-----------------------------------------------------------------------------------------------------
-- CLAPS GUI                                                                                        -
-----------------------------------------------------------------------------------------------------

claps_gui = vb:column{
id="claps_gui",
	style="invisible",
	spacing=SPACING,
	margin=0,
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Claps ~",
				style="strong",
				font="bold",
			},
		},
		make_row("Duration", "claps_duration", 0.001, 2.0, 0.5, {0.1, 1}),
		make_row("Noise amount", "claps_noise_amount", 0.005, 0.99, 0.2, {0.001, 0.01}),
		make_row("Filter", "claps_filter_freq", 100, 8000, 1000, {1, 10}),
		make_row("Filter Q", "claps_filter_Q", 0.1, 20.0, 1, {0.01, 0.1}),
	},
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Claps Envelopes ~",
				style="strong",
				font="bold",
			},
		},
		make_row("Displace time", "claps_delay", 0.01, 0.1, 0.01, {0.001, 0.01}),
		make_row("Attack time", "claps_attack_time", 0.001, 0.1, 0.001, {0.001, 0.01}),
		make_row("Decay time", "claps_decay_time", 0.001, 0.5, 0.1, {0.001, 0.01}),
		make_row("Attack shape", "claps_attack_shape", 1, 9, 1, {0.01, 0.1}),
		make_row("Decay shape", "claps_decay_shape", 1, 9, 8, {0.01, 0.1}),
	},
}
-----------------------------------------------------------------------------------------------------
-- EXPERIMENTAL KARPLUS-STRONG DRUM GENERATOR GUI                                                   -
-----------------------------------------------------------------------------------------------------

karplus_gui = vb:column{
	id="karplus_gui",
	style="invisible",
	spacing=SPACING,
	margin=0,
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Karpus-Strong drum ~",
				style="strong",
				font="bold",
			},
		},
		make_row("Duration", "karplus_duration", 0.001, 2.0, 0.2, {0.1, 1}),
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Noise", width=TEXT_WIDTH},
			vb:popup{
				id="karplus_noise_select",
				width=POPUP_WIDTH,
				items={"White noise", "Pink noise", "Brownian noise"}, --"Sine", "Saw"},
				value=1,
				notifier=function(value)
					render_sample()
				end
			},
		},
		make_row("Stretch", "karplus_stretch", 1, 10, 1, {1, 1}),
		make_row("Wave Len", "karplus_wavelen", 10, 22050, 8000, {2, 4}),
	},
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Filter 1", width=TEXT_WIDTH},
			vb:popup{
				id="karplus_filter1_selector",
				width=POPUP_WIDTH,
				items=FILTERS,
				value=#FILTERS,
				notifier=function(value)
					check_gui_visibility()
					render_sample()
				end
			},
		},
		vb:column{
			id="karplus_filter1_gui",
			style="invisible",
			spacing=0,
			margin=0,
			make_row("Filter 1 freq", "karplus_filter1_freq", 0.0, 10000, 1000, {1, 4}),
			make_row("Filter 1 Q", "karplus_filter1_Q", 0.1, 20, 1, {0.01, 0.1}),
		},
	},
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Filter 2", width=TEXT_WIDTH},
			vb:popup{
				id="karplus_filter2_selector",
				width=POPUP_WIDTH,
				items=FILTERS,
				value=#FILTERS,
				notifier=function(value)
					check_gui_visibility()
					render_sample()
				end
			},
		},
		vb:column{
			id="karplus_filter2_gui",
			style="invisible",
			spacing=0,
			margin=0,
			make_row("Filter 2 freq", "karplus_filter2_freq", 0.0, 10000, 1000, {1, 4}),
			make_row("Filter 2 Q", "karplus_filter2_Q", 0.1, 20, 1, {0.01, 0.1}),
		},
	},
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Filter 3", width=TEXT_WIDTH},
			vb:popup{
				id="karplus_filter3_selector",
				width=POPUP_WIDTH,
				items=FILTERS,
				value=#FILTERS,
				notifier=function(value)
					check_gui_visibility()
					render_sample()
				end
			},
		},
		vb:column{
			id="karplus_filter3_gui",
			style="invisible",
			spacing=0,
			margin=0,
			make_row("Filter 3 freq", "karplus_filter3_freq", 0.0, 10000, 1000, {1, 4}),
			make_row("Filter 3 Q", "karplus_filter3_Q", 0.1, 20, 1, {0.01, 0.1}),
		},
	},
}


-----------------------------------------------------------------------------------------------------
-- GlockenSpiel                                                                                     -
-----------------------------------------------------------------------------------------------------

glocken_gui = vb:column{
	id="glocken_gui",
	style="invisible",
	spacing=SPACING,
	margin=0,
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Glockenspiel & Gong ~",
				style="strong",
				font="bold",
			},
		},
		make_row("Waves", "glocken_osc_selector", 1, 16, 6, {1, 2}),
		make_row("Duration", "glocken_duration", 0.001, 10.0, 3, {0.1, 1}),
		make_row("Frequency", "glocken_frequency", 1, 10000, 4000, {1, 5}),
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Filter", width=TEXT_WIDTH},
			vb:popup{
				id="glocken_filter_selector",
				width=POPUP_WIDTH,
				items=FILTERS,
				value=#FILTERS,
				notifier=function(value)
					render_sample()
				end
			},
		},
		make_row("Filter freq", "glocken_filter_frequency", 1, 10000, 4000, {1, 5}),
		make_row("Filter Q", "glocken_filter_Q", 0.1, 20, 1, {0.01, 0.1}),
		make_row("Delay", "glocken_delay", 12, 10001, 10001, {1, 10}),
		make_row("Decay", "glocken_decay", 0.0, 1, 1, {0.001, 0.01}),
		make_row("Dry / Wet", "glocken_drywet", 0.0, 1.0, 0.8, {0.01, 0.1}),
		make_row("Scaler", "glocken_scaler", 2.0, 6.0, 5.8, {0.01, 0.1}),
		make_row("Tremolo", "glocken_tremolo", 0.0, 1.0, 0.15, {0.01, 0.1}),
		--make_row("Wave", "glocken_wave", 1, 3, 1, {1, 1}),
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Carrier wave", width=TEXT_WIDTH},
			vb:popup{
				id="glocken_wave_selector",
				width=POPUP_WIDTH,
				items={"Sine", "Triangle", "Square", "Xor"},
				value=1,
				notifier=function(value)
					render_sample()
				end
			},
		},
		make_row("Carrier freq", "glocken_carrier_freq", 1, 10000, 124, {1, 10}),
		make_row("Attack", "glocken_env_attack", 0.001, 10, 0.002, {0.001, 0.01}),
		make_row("Decay", "glocken_env_decay", 0.001, 10, 3, {0.001, 0.01}),
	},
}


-----------------------------------------------------------------------------------------------------
-- GLITCHER GUI                                                                                     -
-----------------------------------------------------------------------------------------------------

glitcher_gui = vb:column{
	id="glitcher_gui",
	style="invisible",
	spacing=SPACING,
	margin=0,
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Glitch Maker ~",
				style="strong",
				font="bold",
			},
		},
		make_row("Nr. Glitches", "glitch_nr", 1, 128, 16, {1, 10}, false),
		make_row("Glitch max dur", "glitch_max", 0.01, 1.0, 0.1, {0.01, 0.1}, false),
		make_row("Rev sample prob", "glitch_revsample", 0.0, 1.0, 0.1, {0.01, 0.1}, false),
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Noise mode", width=TEXT_WIDTH},
			vb:popup{
				id="glitch_noise_selector",
				width=POPUP_WIDTH,
				items={"None", "Dust", "White noise", "Pink noise", "Brownian noise"},
				value=1,
			},
		},
		make_row("Noise overlap", "glitch_noise_overlap", 0.0, 0.5, 0.0, {0.001, 0.01}, false),
		--make_row("Sample overlap", "glitch_sample_overlap", 0.0, 1.0, 0.0, {0.001, 0.01}, false),
		vb:row{
			vb:text{text="Normalize", width=TEXT_WIDTH},
			vb:popup{
				id="glitch_normalize_selector",
				width=POPUP_WIDTH,
				items={"None", "Each sample separately", "All samples together"},
				value = 1,
			},
		},
		vb:row{
			vb:text{text="Apply rand ENV", width=TEXT_WIDTH},
			vb:checkbox{id="glitch_env_all", value=false},
		},
	},
}


-----------------------------------------------------------------------------------------------------
-- RENDER AMOUNT                                                                                    -
-----------------------------------------------------------------------------------------------------

function RndAmt(slider)
	-- percentage is 0 .. 1

	local percentage = vbs.morph_perc_slider.value
	local min = slider.min
	local max = slider.max
	local value = 0
	local amount = (max - min) * percentage
	local coin = bernouli(0.5)
	
	if coin == 0 then
		value = slider.value - amount
		if value < min then value = min end
	else
		value = slider.value + amount
		if value > max then value = max end
	end

	return value

end


-----------------------------------------------------------------------------------------------------
-- MASTER GUI
-----------------------------------------------------------------------------------------------------

make_gui = vb:column{
	style="panel",
	spacing=SPACING,
	margin=MARGIN,
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:popup{
				id="drum_switch",
				width=150,
				height=24,
				items={"Kicks & Blips", "Snares", "HiHats", "Cymbals", "Claps", "Karplus", "Bell & Gong", "Glitcher EX"},
				value=1,
				notifier = function(value)
					check_gui_visibility()
				end
			},
			vb:popup{
				id="samplerate",
				width=100,
				height=24,
				items=SAMPLERATES,
				value=3,
				notifier=function(value)
					SAMPLERATE = tonumber(SAMPLERATES[value])
					render_sample()
				end
			},
			vb:popup{
				id="bitrate",
				width=50,
				height=24,
				items=BITRATES,
				value=2,
				notifier=function(value)
					BITRATE = tonumber(BITRATES[value])
					render_sample()
				end
			},
		},
	},
	kick_gui,
	snare_gui,
	hihat_gui,
	cymbal_gui,
	claps_gui,
	karplus_gui,
	glocken_gui,
	glitcher_gui,
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Saturation ~",
				style="strong",
				font="bold",
			},
		},
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Saturation", width=TEXT_WIDTH},
			vb:popup{
				id="saturation_selector",
				width=POPUP_WIDTH,
				items={"None", "Sin", "Tanh", "User"},
				value=1,
				notifier=function(value)
						render_sample()
				end
			},
		},
		make_row("Saturation amt", "saturation_amount", 0.0, 1.0, 0.2, {0.001, 0.01}),
	},
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ Volume envelope ~",
				style="strong",
				font="bold",
			},
		},
		make_row("Master volume", "master_volume", 0.0, 2.0, 0.5, {0.01, 0.1}),
		vb:horizontal_aligner{
			mode="left",
			vb:text{text="Envelope", width=TEXT_WIDTH},
			vb:popup{
				id="envelope",
				width=POPUP_WIDTH,
				items = EASING_FUNCTIONS,
				value=#EASING_FUNCTIONS,
				notifier=function(value)
					check_gui_visibility()
					render_sample()
				end
			},
		},
		make_elastic_gui,
		make_back_gui,
	},
	vb:column{
		style="group",
		spacing=SPACING,
		margin=MARGIN,
		vb:horizontal_aligner{
			mode="distribute",
			vb:text{
				text="~ The Fortune Device ~",
				style="strong",
				font="bold",
			},
		},
		vb:horizontal_aligner{
			mode="distribute",
			vb:button{
				text="Randomize",
				width=150,
				height=24,
				notifier=function()
					randomize_selected_sample(vbs.drum_switch.value)
				end
			},
			vb:button{
				text="Morph",
				width=150,
				height=24,
				notifier=function()
					morph_selected_sample(vbs.drum_switch.value)
				end
			},
		},
		make_row("Morph percentage", "morph_perc", 0.01, 0.2, 0.03, {0.001, 0.01}, false),
	},
}