local vb, STRETCH_DIALOG, SHIFT_DIALOG, MS_DIALOG
local HELP_DIALOG

local RBAPI = Dlt_RubberBandApi()

--=============================================================================
-- Key Handlers
--=============================================================================

function get_keypress (key)
	local modifiers = key.modifiers
	if modifiers ~= '' then
		modifiers = key.modifiers .. ' + '
	end
	return modifiers .. key.name
end


--=============================================================================
-- Generic GUI helpers
--=============================================================================

function _focus_textfield ( control, vb_instance )
	--------------------------------------
	vb_instance = vb_instance or vb
	vb_instance.views[control].edit_mode = true
end


function _cycle_value_up ( control_id, vb_instance )
	-------------------------------------
	vb_instance = vb_instance or vb
	local ctrl = vb_instance.views[control_id]
	local num_items = table.getn(ctrl.items)
	if ctrl.value + 1 > num_items then
		ctrl.value = 1
	else
		ctrl.value = ctrl.value + 1
	end
end


function _cycle_value_down ( control_id, vb_instance )
	---------------------------------------
	vb_instance = vb_instance or vb
	local ctrl = vb_instance.views[control_id]
	local num_items = table.getn(ctrl.items)
	if ctrl.value - 1 < 1 then
		ctrl.value = num_items
	else
		ctrl.value = ctrl.value - 1
	end
end


function _toggle_visibility ( view_id )
	------------------------------------
	vb.views[view_id].visible = ( vb.views[view_id].visible ~= true )
end


function _gui_field_title ( title, text_style, vb_instance )
	---------------------------------------------
	vb_instance = vb_instance or vb
	text_style = text_style or 'strong'
	return 	vb_instance:column {
		width = 100,
		vb_instance:text { style = text_style, text = title },
	}
end


function _option_checkbox ( context, option_name, description, wrap_length )
	wrap_length = wrap_length or 50
	----------------------------------------------------------
	return vb:row {
		vb:checkbox {
			value = context[option_name].value,
			notifier = function(v)
				context[option_name].value = v
			end
		},
		vb:text { text = Util:wordwrap(description, wrap_length) }
	}
end


function _gui_header ( context )
	------------------------------
	return vb:row {
		width = '100%',
		uniform = true,
		vb:horizontal_aligner {
			width = 200,
			mode='left',
			vb:bitmap {
				height = 10,
				width = 90,
				bitmap = 'img/header.'..context..'.bmp',
				mode = 'button_color',
			},

		},
		vb:horizontal_aligner {
			mode = 'right',
			width = 200,
			-- vb:chooser {
			vb:text { text = 'View Mode:' },
			vb:popup {
				width = 80,
				items = {'Simple','Advanced'},
				value = get_advanced_view_value(context),
				notifier = function(v) 
					vb.views.addl_settings.visible = ( v == 2 )
					options[context].gui.show_advanced.value = ( v == 2 ) -- save visibility
				end
			},
			vb:space { width = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING },
			vb:button {
				text = 'Help',
				notifier = function() open_help(context) end,
			},
			vb:space { width = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },
		},
	}
end


-- Specific GUI callback helpers
--=============================================================================

function focus_interval_field ()
	------------------------------
	_focus_textfield('interval_textfield')
end

function get_advanced_view_value ( context )
	if options[context].gui.show_advanced.value == true then
		return 2
	else
		return 1
	end
end


function close_dialog ( dialog )
	------------------------------
	if dialog ~= nil and dialog.visible then
		dialog:close()
	end
end



--=============================================================================
-- Processing Functions
--=============================================================================


function gui_check_sanity () 
	--------------------------
	if not run_sanity_checks() then
		RBAPI.RubberBand.set_status('Nothing selected. Try selecting a sample to work on.')
		-- renoise.app():show_status("RubberBand-Aid: Nothing selected. Try selecting a sample to work on.")
		return false
	end
	return true
end


--=============================================================================
-- D I A L O G : T I M E   S T R E T C H
--=============================================================================




function gui_update_status (vb_button, vb_text_status)
	local w = RBAPI.indicators.working.value
	if w == true then
		vb_button.active = false
	else
		vb_button.active = true
	end
	vb_text_status.visible = true
	vb_text_status.text = RBAPI.indicators.status.value

	local function gui_status_timeout()
		vb_text_status.text = ''
		vb_text_status.visible = false
	end

	if renoise.tool():has_timer(gui_status_timeout) then
		renoise.tool():remove_timer(gui_status_timeout)
	end

	if RBAPI.indicators.status.value == 'Done.'then
		renoise.tool():add_timer(gui_status_timeout, 3000)
	end
end


function open_stretch_dialog ()
	----------------------------
	if not gui_check_sanity() then
		return
	end

	-- Enforce a single active dialog
	close_dialog (SHIFT_DIALOG)	
	close_dialog (MS_DIALOG)

	if STRETCH_DIALOG ~= nil and STRETCH_DIALOG.visible then
		STRETCH_DIALOG:show()
		_focus_textfield('interval_textfield')
		return
	end

	vb = renoise.ViewBuilder()
	STRETCH_DIALOG = nil

	-- Shorthands
	local OPTS = options.stretch

	---------------------------------------------
	local title = "RubberBand-Aid : Time Stretch"
	---------------------------------------------
	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--
	
	local callbacks = 
	{
		RUN = function() 
			--------------
			if not gui_check_sanity() then
				return false
			end

			local unit = OPTS.unit.value
			local interval = OPTS.interval.value

			local opts = {
				-- important
				crisp = OPTS.crispness.value,
				-- optional
				threads = OPTS.threads.value,
				loose = OPTS.loose.value,
				smoothing = OPTS.smoothing.value,
				centerfocus = OPTS.centerfocus.value,
			}

			RBAPI:timestretch(unit, interval, opts)
		end
	}

	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--

	local keyhandler = function ( dialog, key )
		------------------------------------------
		local keypress = get_keypress(key)

		if keypress == 'esc' then
			dialog:close()
			return
		elseif keypress == 'shift + return' then
			callbacks.RUN()
		elseif keypress == 'tab' then
			focus_interval_field()
			return
		elseif keypress == 'left' then
			-- TODO: Decrement the counter
			_cycle_value_down('units_selector', vb)
			return
		elseif keypress == 'right' then
			-- TODO: Increment the counter
			_cycle_value_up('units_selector', vb)
			return
		elseif keypress == 'shift + left' then
			_cycle_value_down('units_selector', vb)
			return
		elseif keypress == 'shift + right' then
			_cycle_value_up('units_selector', vb)
			return
		elseif keypress == 'down' then
			_cycle_value_up('crispness_selector', vb)
			return
		elseif keypress == 'up' then
			_cycle_value_down('crispness_selector', vb)
			return
		elseif keypress == 'option + p' then
			open_shift_dialog()
			return
		elseif keypress == 'option + t' then
			open_stretch_dialog()
			return
		elseif keypress == 'option + =' then
			open_multisample_dialog()
			return
		else
			-- return key
		end
		return key
		--- 
	end

	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--
	-- Set up controls
	-- --------------------------
	
	local crispness_selector = vb:popup {
		id = 'crispness_selector',
		width = 280,
		--[[ Taken from descriptions in rubberband source code ]]
		items = {
			'0: Mushy',
			'1: Piano', 
			'2: Smooth', 
			'3: Balanced multitimbral mixture', 
			'4: Unpitched percussion with stable notes', 
			'5: (Default) Crisp monophonic instrumental', 
			'6: Unpitched solo percussion'
		},
		value = OPTS.crispness.value + 1, -- lua indexes start at 1 :/,
		notifier = function(v)
			OPTS.crispness.value = v - 1
		end
	}

	local interval_textfield = vb:textfield {
		id = 'interval_textfield',
		width = 80,
		value = tostring(OPTS.interval.value),
		notifier = function(v)
			OPTS.interval.value = tonumber(v)
		end
	}

	local units_selector = vb:switch {
		id = 'units_selector',
		width = 200,
		items = {
			'lines', 
			'beats', 
			'seconds', 
			'percent'
		},
		value = OPTS.unit.value,
		notifier = function(v)
			OPTS.unit.value = v
		end
	}

	local BUTTON_text = 'Process Time Stretch'
	local process_button = vb:button {
		width = 200,
		height = 25,
		id = 'stretch_button',
		text = BUTTON_text,
		tooltip = 'Shift + Return',
		pressed = callbacks.RUN
	}
	local process_status = vb:text{
		style = 'strong',
		visible = false,
		align = 'center',
	}
	local update_status = function() gui_update_status(process_button, process_status) end
	-- RBAPI.RubberBand.indicators.working:add_notifier(update_status)
	RBAPI.RubberBand.indicators.status:add_notifier(update_status)

	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--
	
	-- Build the GUI
	-------------------------------

	local content = vb:column {
		style = 'panel',
		margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
		spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
		uniform = true,

		-- HEADER
		-----------------------------
		_gui_header('stretch'),

		vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },

		-- CONTROLS
		-- ---------------------------------
		vb:column {
			style = 'group',
			margin = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
			spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,

			vb:row {
				_gui_field_title('Stretch Settings'),
				vb:column {
					vb:row {
						interval_textfield,
						units_selector
					},
				},
			},

			vb:row {
				_gui_field_title('Crispness'),
				vb:column {
					crispness_selector,
				}
			},
		},


		vb:column {
			id = 'addl_settings',
			style = 'invisible',
			visible = OPTS.gui.show_advanced.value,
			uniform = true,

			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },

			vb:row {
				style = 'group',
				margin = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
				_gui_field_title('Tweaks'),
				vb:column {
					_option_checkbox(OPTS, 'lock_loop_points', 'Lock loop points in time (Do not auto-shift)'),
					_option_checkbox(OPTS, 'lock_slices', 'Lock slice markers in time (Do not auto-shift)'),
					_option_checkbox(OPTS, 'loose', 'Loose: Relax timing in hope of better transient preservation'),
					_option_checkbox(OPTS, 'threads', 'Use multithreading'),
				},
			},

			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },

			vb:row {
				style = 'group',
				margin = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
				_gui_field_title('Experimental\nSettings', 'normal'),
				vb:column {
					_option_checkbox(OPTS, 'centerfocus', 'Center Focus: Preserve focus of centre material in stereo (at a cost in width and individual channel quality)'),
					_option_checkbox(OPTS, 'smoothing', 'Smoothing: Apply window presum and time-domain smoothing (sometimes useful in extreme timestretching)'),
				},
			},
			
		},

		vb:space { height = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN },

		process_status,
		-- BUTTONS
		-- ----------------------------------
		vb:horizontal_aligner {
			mode = 'center',
			process_button,
		},


	}

	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--


	STRETCH_DIALOG = renoise.app():show_custom_dialog( title, content, keyhandler )

	-- Put focus on interval field to be useful from moment one
	_focus_textfield('interval_textfield')
	---
end




--=============================================================================
-- D I A L O G : P I T C H   S H I F T
--=============================================================================

function open_shift_dialog ()
	----------------------------
	if not gui_check_sanity() then
		return
	end

	-- Enforce a single active dialog
	close_dialog (STRETCH_DIALOG)	
	close_dialog (MS_DIALOG)


	if SHIFT_DIALOG ~= nil and SHIFT_DIALOG.visible then
		SHIFT_DIALOG:show()
		describe_shift_amount()
		return
	end

	vb = renoise.ViewBuilder()
	SHIFT_DIALOG = nil

	-- Shorthands
	local OPTS = options.pitch

	---------------------------------------------
	local title = "RubberBand-Aid : Pitch Shift"
	---------------------------------------------
	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--

	local callbacks = 
	{
		RUN = function() 
			--------------
			if not gui_check_sanity() then
				return false
			end

			local cents = OPTS.cents.value

			local opts = {
				--important
				formant = OPTS.preserve_formant.value,
				crisp = OPTS.crispness.value,
				-- optional
				threads = OPTS.threads.value,
				smoothing = OPTS.smoothing.value,
				centerfocus = OPTS.centerfocus.value,
			}
			RBAPI:pitchshift(cents, opts)
		end
	}

	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--
	
	local pitchshift_nudge = function ( amount )
		local el = vb.views.shift_amount
		el.value = el.value + amount
	end

	local keyhandler = function ( dialog, key )
		----------------------------------------
		local keypress = get_keypress(key)

		if keypress == 'esc' then
			dialog:close()
			return
		elseif keypress == 'shift + return' then
			callbacks.RUN()
		elseif keypress == 'tab' then
			-- focus_interval_field()
		elseif keypress == 'left' then
			pitchshift_nudge(-10) 
			return
		elseif keypress == 'right' then
			pitchshift_nudge(10) 
			return
		elseif keypress == 'shift + left' then
			pitchshift_nudge(-100) 
			return
		elseif keypress == 'shift + right' then
			pitchshift_nudge(100) 
			return
		elseif keypress == 'down' then
			_cycle_value_up('crispness_selector', vb)
			return
		elseif keypress == 'up' then
			_cycle_value_down('crispness_selector', vb)
			return
		elseif keypress == 'option + p' then
			open_shift_dialog()
			return
		elseif keypress == 'option + t' then
			open_stretch_dialog()
			return
		elseif keypress == 'option + =' then
			open_multisample_dialog()
			return
		else
			-- return key
		end
		return key
		--- 
	end

	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--

	-- Set up controls
	-- --------------------------

	local describe_shift_amount = function(n)
		n = n or vb.views.shift_amount.value

		local str = Dlt_Util:cents_to_interval(n)
		vb.views.shift_musical_description.font = 'normal'

		local musical_interval = Dlt_Util:cents_to_musical_interval(n)
		if musical_interval then
			str = str..' ('..musical_interval..')'
			vb.views.shift_musical_description.font = 'bold'
		end

		vb.views.shift_musical_description.text = str
	end


	local crispness_selector = vb:popup {
		id = 'crispness_selector',
		width = 280,
		--[[ Taken from descriptions in rubberband source code ]]
		items = {
			'0: Mushy',
			'1: Piano', 
			'2: Smooth', 
			'3: Balanced multitimbral mixture', 
			'4: Unpitched percussion with stable notes', 
			'5: (Default) Crisp monophonic instrumental', 
			'6: Unpitched solo percussion'
		},
		value = OPTS.crispness.value + 1, -- lua indexes start at 1 :/,
		notifier = function(v)
			OPTS.crispness.value = v - 1
		end
	}

	local shift_amount = vb:valuebox {
		id = 'shift_amount',
		width = 150,
		min = -100000,
		max = 100000,
		value = tonumber(OPTS.cents.value),
		notifier = function(v)
			OPTS.cents.value = tonumber(v)
			describe_shift_amount(v)
		end,
		tostring = function(n)
			local str = n .. ' cent'
			if math.abs(n) ~= 1 then str = str..'s' end
			return str
		end,
		tonumber = function(s)
			return tonumber(s)
		end
	}

	local shift_nudge_button = function( label, nudge_amount )
		return vb:button {
			width = 54,
			text = label,
			notifier = function()
				pitchshift_nudge (nudge_amount) 
			end
		}
	end

	local shift_reset_button = function( label )
		return vb:button {
			text = label,
			width = 55,
			color = {200,200,200},
			notifier = function()
				vb.views.shift_amount.value = 0
			end
		}
	end


	local nudge_controls = vb:column{
		uniform = true,
		width = '100%',
		vb:row {
			shift_nudge_button( '-8vb', -1200 ),
			shift_nudge_button( '-1 st', -100 ),
			shift_nudge_button( '-10 c', -10 ),
			shift_reset_button( 'Reset'),
			shift_nudge_button( '+10 c', 10 ),
			shift_nudge_button( '+1 st', 100 ),
			shift_nudge_button( '+8va', 1200 ),
		}
	}

	local BUTTON_text = 'Process Pitch Shift'
	local process_button = vb:button {
		width = 200,
		height = 25,
		id = 'stretch_button',
		text = BUTTON_text,
		tooltip = 'Shift + Return',
		pressed = callbacks.RUN
	}
	local process_status = vb:text{
		style = 'strong',
		visible = false,
		align = 'center',
	}
	local update_status = function() gui_update_status(process_button, process_status) end
	RBAPI.RubberBand.indicators.status:add_notifier(update_status)


	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--

	-- Build the GUI
	-------------------------------

	local content = vb:column {
		style = 'panel',
		margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
		spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
		uniform = true,
	
		-- HEADER
		-----------------------------
		_gui_header('pitch'),


		vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },

		-- CONTROLS
		-- ---------------------------------
		vb:column {
			style = 'group',
			margin = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
			vb:row {
				_gui_field_title('Pitch Shift'),
				vb:column {
					shift_amount,
				},
			},

			vb:space { height = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING },

			vb:row {
				_gui_field_title(''),

				vb:text {
					id = 'shift_musical_description',
					style = 'strong',
					text = '',
				},
			},

			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },

			vb:row {
				nudge_controls
			},

			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },
			
			vb:row {
				_gui_field_title('Crispness'),
				vb:column {
					crispness_selector,
				}
			},
		},


		vb:column {
			id = 'addl_settings',
			style = 'invisible',
			visible = OPTS.gui.show_advanced.value,
			uniform = true,

			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },

			vb:row {
				style = 'group',
				margin = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
				_gui_field_title('Tweaks'),
				vb:column {
					_option_checkbox(OPTS, 'preserve_formant', 'Enable formant preservation when pitch shifting'),
					_option_checkbox(OPTS, 'threads', 'Use multithreading'),
				},
			},

			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },

			vb:row {
				style = 'group',
				margin = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
				_gui_field_title('Experimental\nSettings', 'normal'),
				vb:column {
					_option_checkbox(OPTS, 'centerfocus', 'Center Focus: Preserve focus of centre material in stereo (at a cost in width and individual channel quality)'),
					_option_checkbox(OPTS, 'smoothing', 'Smoothing: Apply window presum and time-domain smoothing (sometimes useful in extreme timestretching)'),
				},
			},
		},

		vb:space { height = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN },


		-- BUTTONS
		-- ----------------------------------
		vb:horizontal_aligner {
			mode = 'center',
			process_button,
		},

		process_status,
	}
	
	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--

	SHIFT_DIALOG = renoise.app():show_custom_dialog( title, content, keyhandler )

	describe_shift_amount()
	---
end





--=============================================================================
-- D I A L O G : M U L T I S A M P L E
--=============================================================================


function open_multisample_dialog ()
	---------------------------------
	if not gui_check_sanity() then
		return
	end

	-- Enforce a single active dialog
	close_dialog (STRETCH_DIALOG)
	close_dialog (SHIFT_DIALOG)

	if MS_DIALOG ~= nil and MS_DIALOG.visible then
		MS_DIALOG:show()
		return
	end

	vb = renoise.ViewBuilder()
	MS_DIALOG = nil

	-- Shorthands
	local OPTS = options.multisample

	---------------------------------------------------------------
	local title = "RubberBand-Aid : Create Multisampled Instrument"
	---------------------------------------------------------------
	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--

	local callbacks = 
	{
		RUN = function() 
			--------------
			if not gui_check_sanity() then
				return false
			end

			local opts = {
				--important
				formant = OPTS.preserve_formant.value,
				crisp = OPTS.crispness.value,
				-- optional
				threads = OPTS.threads.value,
				smoothing = OPTS.smoothing.value,
				apply_microfades = OPTS.apply_microfades.value,
				resample_successively = OPTS.resample_successively.value,
			}
			RBAPI:multisample( OPTS.sample_interval, OPTS.start_note.value, OPTS.end_note.value, opts )
		end
	}

	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--

	local keyhandler = function ( dialog, key )
		----------------------------------------
		local keypress = get_keypress(key)

		if keypress == 'esc' then
			dialog:close()
			return
		elseif keypress == 'shift + return' then
			callbacks.RUN()
		elseif keypress == 'tab' then
			-- focus_interval_field()
		elseif keypress == 'left' then
			_cycle_value_down('units_selector', vb)
			return
		elseif keypress == 'right' then
			_cycle_value_up('units_selector', vb)
			return
		elseif keypress == 'shift + left' then
			-- pitchshift_nudge(-100) 
			return
		elseif keypress == 'shift + right' then
			-- pitchshift_nudge(100) 
			return
		elseif keypress == 'down' then
			_cycle_value_up('crispness_selector', vb)
			return
		elseif keypress == 'up' then
			_cycle_value_down('crispness_selector', vb)
			return
		elseif keypress == 'option + p' then
			open_shift_dialog()
			return
		elseif keypress == 'option + t' then
			open_stretch_dialog()
			return
		elseif keypress == 'option + =' then
			open_multisample_dialog()
			return
		else
			-- return key
		end
		return key
		--- 
	end

	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--
	local crispness_selector = vb:popup {
		id = 'crispness_selector',
		width = 280,
		--[[ Taken from descriptions in rubberband source code ]]
		items = {
			'0: Mushy',
			'1: Piano', 
			'2: Smooth', 
			'3: Balanced multitimbral mixture', 
			'4: Unpitched percussion with stable notes', 
			'5: (Default) Crisp monophonic instrumental', 
			'6: Unpitched solo percussion'
		},
		value = OPTS.crispness.value + 1, -- lua indexes start at 1 :/,
		notifier = function(v)
			OPTS.crispness.value = v - 1
		end
	}

	local interval_to_index = function (interval)
		interval = interval or OPTS.sample_interval.value
		if interval == 12 then
			return 4
		elseif interval == 6 then
			return 3
		elseif interval == 3 then
			return 2
		elseif interval == 1 then
			return 1
		end
	end
	

	local update_size_estimate = function()
		-------------------------------------
		local S = renoise.song().selected_sample
		if not S then
			vb.views.size_estimate.text = 'No sample selected'
			return
		end
		local base_note = S.sample_mapping.base_note
		local num_iterations_down = math.floor((base_note - OPTS.start_note) / OPTS.sample_interval)
		local num_iterations_up = math.floor((OPTS.end_note - base_note) / OPTS.sample_interval)

		local num_samples = 1 + num_iterations_up + num_iterations_down
		local sample_size = S.sample_buffer.number_of_frames * S.sample_buffer.number_of_channels
		local num_keys = OPTS.end_note - OPTS.start_note + 1

		local bytes = num_samples * sample_size * 1.1
		local str = ''
		if bytes > 1000000 then
			str = string.format('%.1f', (bytes/1000000)) .. ' MB'
		else 
			str = string.format('%.1f', (bytes/1000)) .. ' kB'
		end
		str = str .. ' ('..num_samples..' sample'
		if num_samples ~= 1 then
			str = str..'s'
		end
		str = str..' over '..num_keys..' key'
		if num_keys ~= 1 then
			str = str..'s'
		end
		str = str..')'

		vb.views.size_estimate.text = str
	end



	local note_picker = function ( context )
		local notenames_array = { 'C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-' }
		local opt = OPTS[context]
		return vb:valuebox {
			id = 'notepicker_'..context,
			min = 0,
			max = 119,
			value = opt.value,
			tostring = function(v)
				local octave = math.floor(v/12)
				local note = notenames_array[(v%12)+1]
				update_size_estimate()
				return string.format('%s%s', note, octave)
			end,
			tonumber = function(s)
				s = s:upper()
				local octave = s:sub(-1)
				local notename = s:sub(1, 1)
				local quality = s:sub(2,1)
				if quality == '-' or quality == '#' then
					notename = notename .. quality
				else 
					notename = notename .. '-'
				end
				local note = 1
				for i=1, 12 do
					if notenames_array[i] == notename then
						note = i-1
					end
				end
				return (octave*12) + note
			end,
			notifier = function(v)
				-- Enforce min/max here
				if context == 'start_note' then
					vb.views.notepicker_end_note.min = v
					if v > OPTS.end_note.value then
						v = OPTS.end_note.value
					end
				elseif context == 'end_note' then
					vb.views.notepicker_start_note.max = v
					if v < OPTS.start_note.value then
						v = OPTS.start_note.value
					end
				end
				opt.value = v
				update_size_estimate()
			end
		}
	end


	local interval_selector = vb:switch {
		id = 'units_selector',
		width = 280,
		items = {
			'1 semitone', 
			'3 semitones', 
			'6 semitones', 
			'1 octave'
		},
		value = interval_to_index(),
		notifier = function(v)
			local i = 12
			if v == 1 then
				i = 1 -- semitones
			elseif v == 2 then
				i = 3 -- semitones
			elseif v == 3 then
				i = 6 -- semitones
			end
			OPTS.sample_interval.value = i
			update_size_estimate()
		end
	}


	local BUTTON_text = 'Generate Multisample'
	local process_button = vb:button {
		width = 200,
		height = 25,
		id = 'stretch_button',
		text = BUTTON_text,
		tooltip = 'Shift + Return',
		pressed = callbacks.RUN
	}
	local process_status = vb:text{
		style = 'strong',
		visible = false,
		align = 'center',
	}
	local update_status = function() gui_update_status(process_button, process_status) end
	-- RBAPI.RubberBand.indicators.working:add_notifier(update_status)
	RBAPI.RubberBand.indicators.status:add_notifier(update_status)
	-- RBAPI.indicators.working:add_notifier(function() gui_update_status(process_button, process_status) end)
	-- RBAPI.indicators.status:add_notifier(function() gui_update_status(process_button, process_status) end)

	
	local content = vb:column {
		style = 'panel',
		margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
		spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
		uniform = true,
		width = 400,

		-- HEADER
		-----------------------------
		_gui_header('multisample'),

		vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },
		

		vb:column {
			style = 'group',
			margin = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
			vb:row {
				_gui_field_title('Sample Every'),
				vb:column {
						interval_selector
				},
			},

			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },

			vb:row {
				_gui_field_title('Mapping Extent'),
					vb:text { text = 'Start note: ' }, note_picker('start_note'),
					vb:space { width = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },
					vb:text { text = 'End note: ' }, note_picker('end_note'),
					vb:space { width = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },
					vb:button {
						text = 'All',
						notifier = function()
							vb.views.notepicker_start_note.value = 0
							vb.views.notepicker_end_note.value = 119
						end
					}
			},

			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },
			
			vb:row {
				_gui_field_title('Crispness'),
				vb:column {
					crispness_selector,
				}
			},
			
		},

		vb:space { height = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING },

		vb:horizontal_aligner {
			mode = 'center',
			vb:text { text = 'Rough size estimate: ', font='italic' },
			vb:text {
				id = 'size_estimate',
				style = 'strong',
				text = '',
			},
		},


		vb:column {
			id = 'addl_settings',
			style = 'invisible',
			visible = OPTS.gui.show_advanced.value,
			uniform = true,

			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },

			vb:row {
				style = 'group',
				margin = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
				_gui_field_title('Tweaks'),
				vb:column {
					_option_checkbox(OPTS, 'apply_microfades', 'Apply microfades to start/end of each sample'),
					-- TODO: Enable this functionality
					-- _option_checkbox(OPTS, 'create_new_instrument', 'Create new instrument instead of rewriting the current one'),
					_option_checkbox(OPTS, 'preserve_formant', 'Enable formant preservation when pitch shifting'),
					_option_checkbox(OPTS, 'threads', 'Use multithreading'),
				},
			},

			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },

			vb:row {
				style = 'group',
				margin = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
				_gui_field_title('Experimental\nSettings', 'normal'),
				vb:column {
					_option_checkbox(OPTS, 'resample_successively', 
						'Progressive Resample: Repitches each new sample successively from the previous one (instead of basing all repitching on the original sample). Can dramatically alter/mangle the character of the resulting sound.'),
					_option_checkbox(OPTS, 'centerfocus', 
						'Center Focus: Preserve focus of center material in stereo files (at a cost in width and individual channel quality)'),
					_option_checkbox(OPTS, 'smoothing', 
						'Smoothing: Apply window presum and time-domain smoothing (sometimes useful in extreme timestretching)'),
				},
			},
		
			-- },
			-- vb:horizontal_aligner {
				-- mode = 'center',
				-- vb:button {
					-- width = 200,
					-- text = 'Restore Defaults',
					-- pressed = function() restore_defaults('multisample') end
				-- },
			-- },

		},

		vb:space { height = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN },

		process_status,

		-- BUTTONS
		-- ----------------------------------
		vb:horizontal_aligner {
			mode = 'center',
			process_button,
		},


	}

	--====~~~~====~~~~====~~~~====~~~~====~~~~====~~~~====--

	MS_DIALOG = renoise.app():show_custom_dialog( title, content, keyhandler )
	update_size_estimate()
	---
end







--=============================================================================
-- D I A L O G   :   H E L P
--=============================================================================


function open_help ( section )

	section = section or 'config'

	if HELP_DIALOG ~= nil and HELP_DIALOG.visible then
		HELP_DIALOG:close()
	end

	local title = 'RubberBand-Aid'


	local get_help_text = function ( context )
		local text = Util:file_get_contents( renoise.tool().bundle_path..'inc/help.'..context..'.txt' )
		text = text or 'No help text available'
		return text
	end

	-- keep this one local
	local vb = renoise.ViewBuilder()
	HELP_DIALOG = nil

	local hide_section = function (id)
		vb.views['section_'..id].visible = false
	end

	local show_section = function (id)
		hide_section('config')
		hide_section('stretch')
		hide_section('pitch')
		hide_section('multisample')
		vb.views['section_'..id].visible = true
	end

	local page_title = function ( title_text )
		return vb:column {
			vb:horizontal_aligner {
				mode = 'center',
				vb:text {
					font = 'big',
					text = title_text,
					style = 'strong',
				},
			},
			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN },
			vb:bitmap {
				bitmap = 'img/hr.3.bmp',
				mode = 'button_color',
			},
			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN },
		}
	end

	local hr = function()
		return vb:column {
			width = '100%',
			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN },
			vb:bitmap {
				bitmap = 'img/hr.1.bmp',
				mode = 'button_color',
			},
			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },
		}
	end

	local section_heading = function ( heading_text, alignment )
		alignment = alignment or 'left'
		return vb:column {
			width = '100%',
			vb:text {
				text = heading_text,
				style = 'strong',
				font = 'bold',
				width = 380,
				align = alignment,
			},
			vb:space { height = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING },
		}
	end

	local web_link = function ( title, href )
		return vb:button {
			text = title,
			notifier = function ()
				renoise.app():open_url( href )
			end
		}
	end

	local help_section = function ( context, title )
		return vb:column {
			id = 'section_'..context,
			style = 'invisible',
			visible = false,
			width = 400,
			page_title ('Help | '..title),
			vb:multiline_text { 
				width = 400,
				height = 500,
				text = get_help_text( context ) 
			},
		}
	end


	local content = vb:column {
		style = 'body',
		margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
		spacing = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
		width = 400,
		height = 500,

		--[[
		vb:horizontal_aligner {
			mode = 'justify',
			vb:text {
				font = 'big',
				text = 'RubberBand-Aid',
			},
			vb:horizontal_aligner {
				mode = 'right',
				width = 250,
				vb:popup {
					id = 'section_selector',
					width = 150,
					items = {
						'Configuration',
						'Time Stretch', 
						'Pitch Shift', 
						'Multisample Generator', 
					},
					value = 1,
					notifier = function(v)
						if     v == 1 then show_section('config')
						elseif v == 2 then show_section('stretch')
						elseif v == 3 then show_section('pitch')
						elseif v == 4 then show_section('multisample')
						else show_section('config')
						end
					end
				},
			},
		},
		--]]

		help_section ('stretch', 'Time Stretching'),
		help_section ('pitch', 'Pitch Shifting'),
		help_section ('multisample', 'Multisample Generator'),


		-- CONFIGURATION and INSTALLATION TIPS
		-- -----------------------------------
		vb:column {
			id = 'section_config',
			style = 'invisible',
			visible = false,
			width = 400,

			page_title ('Configuration & Installation Tips'),

			section_heading('CONFIGURATION'),
			--------------------------------------
			-- Rubberband binary picker
			vb:text {
				text = 'Path to Rubber Band Binary',
				style='strong',
			},
			rubberband_binary_location_picker(vb),
			--------------------------------------
			
			hr(),

			section_heading('INSTALLATION TIPS'),
			--------------------------------------
			vb:multiline_text {
				-- style = 'border',
				width = 400,
				height = 250,
				style='border',
				text = get_help_text('config'),
			},
			--------------------------------------

			hr(),
			
			section_heading('EXTERNAL LINKS'),
			--------------------------------------
			vb:column {
				-- margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
				spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
				web_link('Rubber Band (https://breakfastquay.com/rubberband/)', 'https://breakfastquay.com/rubberband/'),
				web_link('Libsndfile (https://github.com/erikd/libsndfile/)', 'https://github.com/erikd/libsndfile/'),
				web_link('Homebrew for Mac (https://brew.sh)', 'https://brew.sh'),
			},
			--------------------------------------
		},
	}

	local keyhandler = function(dialog, key)
		local keypress = get_keypress(key)

		if keypress == 'esc' then
			dialog:close()
			return
		elseif keypress == 'right' or keypress == 'down' then
			_cycle_value_up('section_selector', vb)
			return
		elseif keypress == 'left' or keypress == 'up' then
			_cycle_value_down('section_selector', vb)
			return
		else
			-- return key
		end
		return key

	end

	HELP_DIALOG = renoise.app():show_custom_dialog( title, content, keyhandler )
	show_section(section)
end





















function rubberband_binary_location_picker ( vb_context )
	-------------------------------------------------------
	local vb = vb_context or vb

	return vb:column {
		style = "group",
		margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
		spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
		uniform = true,
		width='100%',
		vb:multiline_textfield {
			id = "path_to_rubberband",
			width='100%',
			height=36,
			font = 'mono',
			text = options.path_to_rubberband.value,
			notifier = function ()
				options.path_to_rubberband.value = vb.views.path_to_rubberband.text
			end
		},

		vb:horizontal_aligner {
			mode = 'center',
			vb:button {
				text = 'Browse...',
				notifier = function()
					local path = ''
					if os.platform() == 'WINDOWS' then
						path = renoise.app():prompt_for_filename_to_read({'*','*.rubberband','*.exe','rubberband'}, 'Choose Rubber Band binary')
					else
						path = renoise.app():prompt_for_path('Choose Rubber Band binary')
						path = path..'rubberband'
						if os.platform() == 'MACINTOSH' and path ~= 'rubberband' then
							io.chmod(path, 755)
						end
					end

					if path == '' then
						path = get_rubberband_binary()
					end
					vb.views.path_to_rubberband.text = path
					-- vb.views.path_to_rubberband.tooltip = path
					options.path_to_rubberband.value = path
				end	
			},
			vb:button {
				text = 'Reset to Default',
				notifier = function()
					local path = get_rubberband_binary()
					vb.views.path_to_rubberband.text = path
					options.path_to_rubberband.value = path
				end	
			},
		},
	}
end

