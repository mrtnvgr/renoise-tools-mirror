--[[ FILE INFO |
------------------------------------------------------------------------------
___ _  _ ____    ___  ____ _    _ _  _ ____ ____ ____ ____
 |  |__| |___    |  \ |___ |    | |  | |___ |__/ |___ |__/
 |  |  | |___    |__/ |___ |___ |  \/  |___ |  \ |___ |  \
                 ____ _  _ _
                 |__, |__| |

	DLT <dave.tichy@gmail.com>
------------------------------------------------------------------------------
  INTERFACE
---------------------------------------------------------------------------
Copyright © 2020 David Lopez Tichy, http://dlt.fm <dave.tichy@gmail.com>
---------------------------------------------------------------------------
The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
---------------------------------------------------------------------------

===========================================================================]]

class 'DlvrrGui'

-----------------------------------------------------------------------------

DlvrrGui.keyhandler = function (dialog, key)
	-- if key.name == 'return' then
		-- self:run_render()
		-- return nil
	-- elseif key.name == 'esc' then
		-- self:cancel_render()
		-- return nil
	-- end
	-- return key

	-- Don't let any keystrokes through. We don't want to screw with the song
	-- inadvertently.
	return nil
end

-----------------------------------------------------------------------------

function DlvrrGui:__init()

	self.SPACING = 5
	self.PANEL_WIDTH = 450

	self.vb = renoise.ViewBuilder()
	self.deliverer = Dlvrr()
	self.content = nil

	self.dialog = nil

	self.editing_enabled = renoise.Document.ObservableBoolean(true)
	self.settings_tab = renoise.Document.ObservableNumber(1)

	self.batch_start_time = nil

	-- General OK signal
	self.ok_status = renoise.Document.ObservableBoolean(true)
	self.deliverer.ok_status:add_notifier(function()
		self.ok_status.value = self.deliverer.ok_status.value
	end)

	self.acceptable_tokens = {
		{'ARTIST', 'From song comments'},
		{'ARTIST_NS', 'Artist (No spaces)'},
		{'ARTIST_INIT', 'Artist initials'},
		{'SONGNAME', 'From song comments'},
		{'SONGNAME_NS', 'Song name (No spaces)'},
		{'TRACKNUM', 'Stem/track number (Stems ONLY)'},
		{'TRACKNAME', 'Track name'},
		{'TRACKNAME_NS', 'Track name (No spaces)'},
		{'MUTESTATE', 'Mute state: ACTIVE/MUTED/OFF (Stems)'},
		{'BITDEPTH', 'Output bit depth'},
		{'SAMPLERATE', 'Output sample rate'},
		{'BPM', 'Beats per minute (starting)'},
		{'YEAR', 'Year (4-digit)'},
		{'YR', 'Year (2-digit)'},
		{'MO', 'Month (2-digit)'},
		{'DD', 'Day (2-digit)'},
		{'DATE', 'Date (YYYY-MM-DD)'},
		{'DATE2', 'Date (YYYY.MM.DD)'},
		{'DATE3', 'Date (YYYYMMDD)'},
		{'HH', 'Hour, 24-hour clock (2-digit)'},
		{'HH12', 'Hour, 12-hour clock (2-digit)'},
		{'MM', 'Minute (2-digit)'},
		{'TIME', 'Time, 24-hour clock (HH:MM)'},
		{'TIME2', 'Time, 24-hour clock (HH.MM)'},
		{'TIME3', 'Time, 24-hour clock (HHMM)'},
		{'TIME_PM', 'Time, 12-hour clock (HH:MMpm)'},
		{'TIME_PM2', 'Time, 12-hour clock (HH.MMpm)'},
		{'TIME_PM3', 'Time, 12-hour clock (HHMMpm)'},
	}

	self.acceptable_token_string = ''
	-- for k,v in pairs(self.acceptable_tokens) do
	for i=1, #self.acceptable_tokens do
		local token = self.acceptable_tokens[i][1]
		local desc = self.acceptable_tokens[i][2]

		local token_string = '{'..token..'}'
		for i=token:len(), 14 do
			token_string = token_string..' '
		end
		token_string = token_string .. desc..'\n'
		
		self.acceptable_token_string = self.acceptable_token_string .. token_string
	end
	
end

-----------------------------------------------------------------------------

function DlvrrGui:open()

	if self.dialog and self.dialog.visible then
		self.dialog:show()
		return
	end

	if not self.content then
		self:build_gui()
	end
	self.working_context.text = ''
	self.text_working_on.text = ''
	self.dialog = renoise.app():show_custom_dialog('The DELIVERER', self.content, self.keyhandler)
	
end




--===========================================================================
--     _ __ _ ___ ____ ____ ____ ____ ____ ____
--     | | \|  |  |=== |--< |--- |--| |___ |===
--
--     B U I L D   I N T E R F A C E
-----------------------------------------------------------------------------

function DlvrrGui:build_gui()

	local SPACE = self.SPACING
	local WIDTH = self.PANEL_WIDTH


	self.progress_bar_batch = self.vb:minislider {
		width = WIDTH-(2*SPACE),
		min = 0,
		max = 1,
		active = false,
		bind = self.deliverer.indicators.batch_progress,
	}

	self.progress_bar = self.vb:rotary {
		min = 0,
		max = 1,
		active = false,
		bind = self.deliverer.indicators.progress,
	}

	self.working_context = self.vb:text {
	}
	self.text_working_on = self.vb:text {
		style = 'strong',
	}

	self.deliverer.indicators.currently_rendering:add_notifier(function()
		local i = self.deliverer.indicators
		self.working_context.text = 'Rendering '.. i.render_context.value .. ':'
		self.text_working_on.text = i.currently_rendering.value
	end)
	self.deliverer.indicators.currently_saving:add_notifier(function()
		local i = self.deliverer.indicators
		self.working_context.text = 'Saving '.. i.saving_context.value ..':'
		self.text_working_on.text = self.deliverer.indicators.currently_saving.value
	end)


	local function path_picker(label, id, bound_observable, input_tooltip, button_tooltip, text_align)
		input_tooltip = input_tooltip or nil
		button_tooltip = button_tooltip or nil
		text_align = text_align or 'left'
		local ctl = self.vb:row {
			self.vb:text {
				width = 95,
				text = label,
				align = text_align,
			},
			self.vb:textfield {
				id = id,
				width = WIDTH-150-(6*SPACE),
				text = bound_observable.value,
				bind = bound_observable,
				tooltip = input_tooltip,
			},
			self.vb:button {
				id = id..'_picker',
				width = 55,
				text = 'Browse',
				notifier = function()
					local path = renoise.app():prompt_for_path(label)
					if path ~= '' then
						bound_observable.value = path
					end
				end,
				tooltip = button_tooltip,
			},
		}
		-- disable editing when running
		self.editing_enabled:add_notifier(function()
			self.vb.views[id].active = self.editing_enabled.value
			self.vb.views[id..'_picker'].active = self.editing_enabled.value
		end)
		return ctl
	end


	local function bool_option (label, id, bound_observable, text_style)
		text_style = text_style or 'normal'
		local ctl = self.vb:row {
			self.vb:space { width = SPACE },
			self.vb:checkbox {
				id = id,
				-- value = bound_observable.value,
				bind = bound_observable,
			},
			self.vb:text {
				-- width = 350,
				style = text_style,
				text = label,
			},
		}
		-- disable editing when running
		self.editing_enabled:add_notifier(function()
			self.vb.views[id].active = self.editing_enabled.value
		end)
		return ctl
	end

	local function _find_in (list, item, default)
		default = default or nil
		for i=1, #list do
			if list[i] == item then
				return i
			end
		end
		return default
	end


	local function picker_default (items, item_labels, label, id, bound_observable)
		local ctl = self.vb:row {
			self.vb:text {
				width = 100,
				text = label,
			},
			self.vb:space { width = SPACE },
			self.vb:popup {
				width = WIDTH-100-(7*SPACE),
				id = id,
				items = item_labels,
				value = _find_in (items, bound_observable.value, 32),
				notifier = function()
					bound_observable.value = items[self.vb.views[id].value]
				end
			},
		}
		-- disable editing when running
		self.editing_enabled:add_notifier(function()
			self.vb.views[id].active = self.editing_enabled.value
		end)
		bound_observable:add_notifier(function()
			self.vb.views[id].value = _find_in (items, bound_observable.value)
		end)
		return ctl
	end

	local function picker_bit_depth (label, id, bound_observable)
		local items =       { 16,      24,      32}
		local item_labels = {'16 Bit','24 Bit','32 Bit'}
		return picker_default(items, item_labels, label, id, bound_observable)
	end

	local function picker_sample_rate (label, id, bound_observable)
		local items =       { 22050,      44100,      48000,      88200,      96000,      192000}
		local item_labels = {'22050 Hz', '44100 Hz', '48000 Hz', '88200 Hz', '96000 Hz', '192000 Hz'}
		return picker_default(items, item_labels, label, id, bound_observable)
	end

	local function picker_interpolation (label, id, bound_observable)
		local items =       {'default',             'precise'}
		local item_labels = {'Default (as played)', 'Precise (HQ, but slow)'}
		return picker_default(items, item_labels, label, id, bound_observable)
	end

	local function picker_priority (label, id, bound_observable)
		local items =       {'realtime',           'low',                       'high'}
		local item_labels = {'Realtime rendering', 'Low (render in background', 'High (as fast as possible'}
		return picker_default(items, item_labels, label, id, bound_observable)
	end

	local function picker_sample_export_format (bound_observable)
		local items =       {'flac',                     'wav'}
		local item_labels = {'FLAC (Lossless, compact)', 'WAV'}
		return picker_default(items, item_labels, 'Sample format', 'export_format_samples', self.deliverer.options.export_format_samples)
	end



	local optionpanel_mixdowns = self.vb:row{
		-- visible = self.deliverer.options.include_mixdown.value,
		margin = SPACE,
		-- indent(),
		self.vb:column {
			style = 'group',
			margin = SPACE,
			self.vb:text { style='strong',font='bold',text='Render Settings: Master Mixdown' },
			self.vb:space {height=3,width=WIDTH-(6*SPACE)},
			picker_bit_depth('Bit depth', 'bit_depth_mixdown', self.deliverer.options.render_mixdown_bit_depth),
			picker_sample_rate('Sample rate', 'sample_rate_mixdown', self.deliverer.options.render_mixdown_sample_rate),
			picker_interpolation('Interpolation', 'interpolation_mixdown', self.deliverer.options.render_mixdown_interpolation),
			picker_priority('Priority', 'priority_mixdown', self.deliverer.options.render_mixdown_priority),
			self.vb:space {height=5},
		},
	}

	local optionpanel_stems = self.vb:row {
		margin = SPACE,
		-- indent(),
		self.vb:column {
			width = '100%',
			style = 'group',
			margin = SPACE,
			self.vb:text { style='strong',font='bold',text='Render Settings: Stems' },
			self.vb:space {height=3,width=WIDTH-(6*SPACE)},
			picker_bit_depth('Bit depth', 'bit_depth_stems', self.deliverer.options.render_stems_bit_depth),
			picker_sample_rate('Sample rate', 'sample_rate_stems', self.deliverer.options.render_stems_sample_rate),
			picker_interpolation('Interpolation', 'interpolation_stems', self.deliverer.options.render_stems_interpolation),
			picker_priority('Priority', 'priority_stems', self.deliverer.options.render_stems_priority),
			self.vb:space {height=5},
		},
	}

	local optionpanel_samples = self.vb:row {
		margin = SPACE,
		-- indent(),
		self.vb:column {
			style = 'group',
			margin = SPACE,
			self.vb:text { style='strong',font='bold',text='Export Settings: Raw Samples' },
			self.vb:space {height=3,width=WIDTH-(6*SPACE)},
			picker_sample_export_format(),
			self.vb:text {
				font = 'italic',
				text = 'Note that exported samples will NOT have loop markers conserved.',
			}
		},
	}


	local naming_example = function (for_stems)
		for_stems = for_stems or nil
		if for_stems then
			local stems = ''
			stems = stems .. self.deliverer:name_stem(1, renoise.song().tracks[1])..'.wav\n'
			stems = stems .. self.deliverer:name_stem(2, renoise.song().tracks[2])..'.wav\n'
			stems = stems .. '...'
			return stems
		else
			return self.deliverer:sanitize_filename(self.deliverer:name_mixdown())..'.wav'
		end
	end


	-- Hook in the preset GUI
	local PRESET_GUI = Dlt_PresetGui(self.vb, self.deliverer.presets, 'Factory/')
	-- PRESET_GUI.factory_preset_prefix = 'Factory preset: '
	PRESET_GUI.factory_preset_prefix = 'Factory: '
	PRESET_GUI.use_icons_for_buttons = true
	PRESET_GUI.viewbuilder_view_id = 'preset_picker'


	self.content = self.vb:column {
		width = WIDTH,
		style = 'body',

		PRESET_GUI:preset_picker( WIDTH, WIDTH-100 ),

		self.vb:column {
			width = WIDTH,
			margin = SPACE,
			style = 'panel',
			self.progress_bar_batch,
			self.vb:row {
				self.vb:space { width = SPACE },
				self.progress_bar,
				self.vb:space { width = SPACE },
				self.vb:column {
					spacing = -3,
					self.working_context,
					self.text_working_on,
				},
			},
		},

		self.vb:row {
			id = 'status_panel',
			margin = SPACE,
			style = 'border',
			visible = false,
			width = WIDTH-(2*SPACE),
			self.vb:multiline_text {
				id = 'status_panel_text',
				width = WIDTH-(2*SPACE),
				height = 50,
				style = 'strong',
				font = 'italic',
				text = '',
			},
		},

		self.vb:switch {
			id = 'tab_switch',
			width=WIDTH,
			height=24,
			items = {
				'What & Where',
				'Naming',
				'Output Settings',
				'Show All',
			},
			value = self.deliverer.prefs.gui.last_tab.value,
			bind = self.settings_tab
		},

		-- Settings Panel --
		--------------------
		self.vb:column {
			id = 'settings_panel',
			width = WIDTH-(2*SPACE),
			margin = SPACE,

			-- Export Paths --
			-- ------------
			self.vb:column {
				id = 'tab_paths',

				self.vb:row {
					margin = 5,
					self.vb:column {
						width=WIDTH-(3*SPACE),
						style = 'group',
						margin = SPACE,

						self.vb:text {
							style = 'strong',
							font = 'bold',
							text = 'What to Export',
						},
						self.vb:space {height=3,width=WIDTH-(6*SPACE)},
						bool_option('Render Mixdown', 'include_mixdown', self.deliverer.options.include_mixdown, 'strong'),
						bool_option('Render Stems', 'include_stems', self.deliverer.options.include_stems, 'strong'),
						self.vb:horizontal_aligner {
							id = 'stem_includes',
							-- mode='justify',
							visible = self.deliverer.options.include_stems.value,
							self.vb:space {width=24},
							self.vb:text { text='Which Stems?' },
							self.vb:space {width=SPACE},
							bool_option('Normal tracks', 'stems_include_tracks', self.deliverer.options.stems_include_tracks),
							self.vb:space {width=SPACE},
							bool_option('Groups (Submixes)', 'stems_include_groups', self.deliverer.options.stems_include_groups),
						},
						bool_option('Export XRNI Instruments', 'include_xrni', self.deliverer.options.include_xrni,'strong'),
						bool_option('Export Raw Samples', 'include_samples', self.deliverer.options.include_samples,'strong'),

					},
				},

				self.vb:row {
					margin = 5,
					self.vb:column {
						width=WIDTH-(4*SPACE),
						style = 'group',
						margin = SPACE,

						self.vb:text {
							style = 'strong',
							font = 'bold',
							text = 'Export Paths',
						},
						path_picker('Base (Mixdowns)', 'save_path_mixdown', self.deliverer.options.save_path_mixdown,
							'Rendered mixdowns will be placed here. *Must be an absolute path.*\n\nUsed as the base path for any relative paths specified below.',
							'Choose another folder where rendered Mixdowns should be placed'
							),
						path_picker('Stems', 'save_path_stems', self.deliverer.options.save_path_stems,
							'Entering a relative path here (like "Stems/") will create a Stems folder inside of the Base folder specified above.\n\nSelecting an absolute path will place all Stems directly into the specified folder.',
							'Choose another folder where rendered Stems should be placed'
							),
						path_picker('Instruments', 'save_path_xrni', self.deliverer.options.save_path_xrni,
							'Entering a relative path here (like "Instruments/") will create an Instruments folder inside of the Base folder specified above.\n\nSelecting an absolute path will place all exported Instruments directly into the specified folder.',
							'Choose another folder where exported Instruments should be placed'
							),
						path_picker('Samples', 'save_path_samples', self.deliverer.options.save_path_samples,
							'Entering a relative path here (like "Samples/") will create a Samples folder inside of the Base folder specified above.\n\nSelecting an absolute path will place all exported Samples directly into the specified folder.',
							'Choose another folder where raw exported Samples should be placed'
							),


						self.vb:row {
							spacing = SPACE,
							self.vb:text {
								width = 90,
								text = 'Variables'
							},
							self.vb:column {
								style = 'group',
								self.vb:multiline_text {
									width = WIDTH-90-(7*SPACE),
									height = 60,
									font = 'mono',
									text = [[
{SONGABSPATH}  Path to current song's folder
{SONGNAME}     Current song name
{SONGNAME_NS}  Song name (No spaces)
{FILENAME}     Current song filename]]
-- {FILENAME}     Song filename
								},
							},
						},

					},
				},
			},


			-- TAB: Output Settings --
			-- --------------------
			self.vb:column {
				id = 'tab_output',
				optionpanel_mixdowns,
				optionpanel_stems,
				optionpanel_samples,
			},


			-- TAB: Naming Prefs --
			-- -----------------
			self.vb:column {
				id = 'tab_naming',
				self.vb:row {
					margin = SPACE,
					self.vb:column {
						width=WIDTH-(4*SPACE),
						style = 'group',
						margin = SPACE,

						self.vb:horizontal_aligner {
							mode = 'justify',
							self.vb:text {
								style = 'strong',
								font = 'bold',
								text = 'Naming Preferences',
							},
							self.vb:column{
								self.vb:button {
									id = 'song_comments_button',
									text = 'Edit Song Title / Artist',
									notifier = function()
										self.vb.views.song_comments.visible = true
										self.vb.views.song_comments_button.visible = false
									end
								},
							},
						},
						self.vb:space {height=3,width=WIDTH-(6*SPACE)},

						self.vb:column {
							id = 'song_comments',
							visible = false,
							self.vb:row {
								spacing = SPACE,
								self.vb:text {
									width = 70,
									text = 'Song Title'
								},
								self.vb:textfield {
									width = WIDTH-70-(7*SPACE),
									text = renoise.song().name,
									bind = renoise.song().name_observable,
								},
							},
							self.vb:row {
								spacing = SPACE,
								self.vb:text {
									width = 70,
									text = 'Song Artist'
								},
								self.vb:textfield {
									width = WIDTH-70-(7*SPACE),
									text = renoise.song().artist,
									bind = renoise.song().artist_observable,
								},
							},
							self.vb:space {height=3,width=WIDTH-(6*SPACE)},
						},

						self.vb:column {
							style = 'border',
							margin=SPACE,
							width = WIDTH-(6*SPACE),
							self.vb:row {
								spacing = SPACE,
								self.vb:text {
									text = 'Mixdown:',
									align='right',
									width = 60
								},
								self.vb:text {
									id = 'naming_example',
									width = WIDTH-60-(9*SPACE),
									style = 'strong',
									font = 'mono',
									text = '', --naming_example()
								},
							},
							self.vb:space {height=1,width=355},
							self.vb:row {
								spacing = SPACE,
								self.vb:text {text = 'Stems:',
									align='right',
									width = 60
								},
								self.vb:text {
									id = 'naming_example_stem',
									width = WIDTH-60-(9*SPACE),
									style = 'strong',
									font = 'mono',
									text = '', --naming_example(true)
								},
							},
						},
						self.vb:space {height=5,width=WIDTH-(6*SPACE)},
						bool_option('Use Grammy Producers & Engineers Wing recommendations', 'use_grammy_naming', self.deliverer.options.use_grammy_naming),
						self.vb:row{
							self.vb:space {width=24},
							self.vb:button{
								text = 'What\'s this?',
								notifier = function()
									renoise.app():open_url('https://www.grammy.com/technical-guidelines')
								end
							},
						},


					},
				},

				self.vb:row {
					id = 'custom_naming_panel',
					margin = SPACE,
					visible = (self.deliverer.options.use_grammy_naming.value == false),
					self.vb:column {
						width=WIDTH-(4*SPACE),
						style = 'group',
						margin = 5,
						self.vb:text {
							text = 'Custom Naming Scheme',
							style = 'strong',
							font= 'bold',
						},
						self.vb:row {
							spacing = SPACE,
							self.vb:text {
								width = 70,
								text = 'Mixdown'
							},
							self.vb:textfield {
								width = WIDTH-70-(7*SPACE),
								-- text = '{ARTIST} - {SONGNAME}',
								text = self.deliverer.options.naming_format_mixdown.value,
								bind = self.deliverer.options.naming_format_mixdown,
							},
						},
						self.vb:row {
							spacing = SPACE,
							self.vb:text {
								width = 70,
								text = 'Stems'
							},
							self.vb:textfield {
								width = WIDTH-70-(7*SPACE),
								-- text = '{TRACKNUMBER}. {TRACKNAME}',
								text = self.deliverer.options.naming_format_stems.value,
								bind = self.deliverer.options.naming_format_stems,
							},
						},
						self.vb:space { height=3 },
						self.vb:row {
							spacing = SPACE,
							self.vb:column {
								self.vb:text {
									width = 70,
									text = 'Variables'
								},
								self.vb:button {
									text = 'View All',
									notifier = function() self:open_token_key() end,
								},
							},
							self.vb:column {
								style = 'group',
								self.vb:multiline_text {
									width = WIDTH-70-(7*SPACE),
									height = 60,
									font = 'mono',
									text = self.acceptable_token_string
								},
							},
						}



					},
				},
			},



		},

		-- Buttons --
		-- ------------
		self.vb:horizontal_aligner {
			mode = 'center',
			margin = SPACE,
			self.vb:button {
				height=30,
				width=150,
				id = 'button_run',
				text = 'Export Deliverables',
				notifier = function() self:show_preflight_dialog() end
			},
			self.vb:button {
				height=30,
				width=150,
				id = 'button_abort',
				text = 'Stop Exporting',
				visible = false,
				notifier = function() self:cancel_render() end
			},
		},
		-- self.vb:space { height = 10 },

		-- --------------
	}


	-- Monitor Observables --
	-- ----------------------
	self.deliverer.ok_status:add_notifier(function()
		if self.deliverer.ok_status.value == false then
			self:fail()
		end
	end)

	self.editing_enabled:add_notifier(function()
		self.vb.views.button_run.active = self.editing_enabled.value
		self.vb.views.button_run.visible = self.editing_enabled.value
		self.vb.views.button_abort.visible = (self.editing_enabled.value == false)

		self.vb.views.tab_switch.visible = self.editing_enabled.value
		self.vb.views.settings_panel.visible = self.editing_enabled.value

		self.vb.views.preset_picker.visible = self.editing_enabled.value
	end)

	self.deliverer.options.include_stems:add_notifier(function()
		self.vb.views.stem_includes.visible = self.deliverer.options.include_stems.value
	end)

	local function update_example_names()
		self.vb.views.naming_example.text = naming_example()
		self.vb.views.naming_example_stem.text = naming_example(true)
	end
	self.deliverer.options.use_grammy_naming:add_notifier(update_example_names)
	self.deliverer.options.render_stems_bit_depth:add_notifier(update_example_names)
	self.deliverer.options.render_stems_sample_rate:add_notifier(update_example_names)
	self.deliverer.options.render_mixdown_bit_depth:add_notifier(update_example_names)
	self.deliverer.options.render_mixdown_sample_rate:add_notifier(update_example_names)
	self.deliverer.options.naming_format_stems:add_notifier(update_example_names)
	self.deliverer.options.naming_format_mixdown:add_notifier(update_example_names)
	renoise.song().name_observable:add_notifier(update_example_names)
	renoise.song().artist_observable:add_notifier(update_example_names)

	renoise.tool().app_new_document_observable:add_notifier(function()
		renoise.song().artist_observable:add_notifier(update_example_names)
		renoise.song().name_observable:add_notifier(update_example_names)
		update_example_names()
	end)

	self.deliverer.options.use_grammy_naming:add_notifier(function()
		self.vb.views.custom_naming_panel.visible = self.deliverer.options.use_grammy_naming.value == false
	end)

	local function update_tab_page()
		local tab = self.settings_tab.value
		self.deliverer.prefs.gui.last_tab.value = tab

		self.vb.views.tab_paths.visible = false
		self.vb.views.tab_output.visible = false
		self.vb.views.tab_naming.visible = false

		if tab == 1 then
			self.vb.views.tab_paths.visible = true
		elseif tab == 2 then
			self.vb.views.tab_naming.visible = true
		elseif tab == 3 then
			self.vb.views.tab_output.visible = true
		elseif tab == 4 then
			self.vb.views.tab_paths.visible = true
			self.vb.views.tab_naming.visible = true
			self.vb.views.tab_output.visible = true
		end
	end

	self.settings_tab:add_notifier(update_tab_page)
	update_tab_page()

	self.deliverer.status_message:add_notifier(function()
		self.vb.views.status_panel_text.text = self.deliverer.status_message.value
	end)


	if self.deliverer.ok_status == false then
		self:fail()
	end

	update_example_names()
	-- When we change a preset, or otherwise need to update the whole GUI
	-- self.deliverer.preset_changed:add_notifier(function()
		-- self:build_gui()
	-- end)

end

-----------------------------------------------------------------------------


--===========================================================================
--     ____ ____ ___ _ ____ __ _ ____
--     |--| |___  |  | [__] | \| ====
--
--     C O N T R O L L E R S  /  A C T I O N S
-----------------------------------------------------------------------------

function DlvrrGui:run_render()

	self.editing_enabled.value = false
	self.vb.views.status_panel.visible = false

	-- IMPORTANT
	self.deliverer.ok_status.value = true -- reset status

	self.batch_start_time = os.clock()

	self.deliverer:init_batch()

	if self.deliverer.options.include_mixdown.value == true then
		self.deliverer:render_mixdown()
	end
	if self.deliverer.options.include_stems.value == true then
		self.deliverer:render_all_stems()
	end
	if self.deliverer.options.include_xrni.value == true then
		self.deliverer:save_all_instruments()
	end
	if self.deliverer.options.include_samples.value == true then
		self.deliverer:save_all_samples()
	end

	TASKER:add_task(function() self:show_summary() end)
end

-----------------------------------------------------------------------------

function DlvrrGui:show_preflight_dialog()

	local WIDGET_WIDTH = 500
	local DLV = self.deliverer

	local function wrap_section (title, content)
		return self.vb:column {
			margin = self.SPACING,
			spacing = 3,
			style = 'group',
			width = WIDGET_WIDTH-10,
			self.vb:text {
				style='strong',
				font='bold',
				text=title,
			},
			content
		}
	end
	local function text (str, width)
		width = width or nil
		return self.vb:text {text=str, width=width}
	end
	local function strong (str)
		return self.vb:text {style='strong',font='bold', text=str}
	end
	local function multiline (str, height)
		height = height or 32
		return self.vb:multiline_text { width=WIDGET_WIDTH-10,height=height,text=str }
	end
	local function multiline_strong (str, height)
		height = height or nil
		return self.vb:multiline_text { style='border',width=WIDGET_WIDTH-110,height=height,text=str }
	end

	-- M I X D O W N
	-- ---------------------
	local function mixdown()
		if DLV.options.include_mixdown.value ~= true then return nil end
		--
		local path = DLV:get_path_for(Dlvrr.CONTEXT_MIXDOWN)
		return wrap_section('Mixdown', self.vb:column {
			multiline(path),
			self.vb:row {
				text('Render settings:'),
				strong(table.concat({
						DLV.TAILOR:sample_rate_abbrev(DLV.options.render_mixdown_sample_rate.value)..'Hz',
						DLV.options.render_mixdown_bit_depth.value..'-bit',
						DLV.options.render_mixdown_interpolation.value..' interpolation',
						DLV.options.render_mixdown_priority.value..' priority',
					}, ', ')),
			},
			self.vb:row {
				text('Filename:'),
				multiline_strong( DLV:name_mixdown()..'.wav' ),
			},
			-- self.vb:row {
				-- text('Save to:', 90),
				-- text(path),
			-- },
		})
	end

	-- S T E M S
	-- --------------------
	local function stems()
		if DLV.options.include_stems.value ~= true then return nil end
		local path = DLV:get_path_for(Dlvrr.CONTEXT_STEM)
		local stem_filenames = {}
		for idx=1, #renoise.song().tracks do
			if DLV:stem_should_render(renoise.song().tracks[idx]) then
				local t = renoise.song():track(idx)
				table.insert(stem_filenames, DLV:name_stem(idx, t)..'.wav')
			end
		end
		--
		return wrap_section('Stems', self.vb:column {
			multiline(path),
			self.vb:row {
				text('Render settings:', 90),
				strong(table.concat({
						DLV.TAILOR:sample_rate_abbrev(DLV.options.render_stems_sample_rate.value)..'Hz',
						DLV.options.render_stems_bit_depth.value..'-bit',
						DLV.options.render_stems_interpolation.value..' interpolation',
						DLV.options.render_stems_priority.value..' priority',
					}, ', ')),
			},
			self.vb:row {
				text('Filenames:', 90),
				multiline_strong( table.concat(stem_filenames, '\n'), 60 ),
			},
			-- self.vb:row {
				-- text('Save to:', 90),
				-- text(path),
			-- },
		})
	end

	-- X R N I
	-- -------------------
	local function xrni()
		if DLV.options.include_xrni.value ~= true then return nil end
		--
		local xrni_filenames = {}
		local path = DLV:get_path_for(Dlvrr.CONTEXT_XRNI)
		for idx=1, #renoise.song().instruments do
			local I = renoise.song():instrument(idx)
			table.insert(xrni_filenames, DLV:filename_xrni(idx, I.name)..'.xrni')
		end
		return wrap_section('XRNI Instruments', self.vb:column {
			multiline(path),
			-- self.vb:space {height=5},
			self.vb:row {
				text('Filenames:', 90),
				multiline_strong( table.concat(xrni_filenames, '\n'), 60 ),
			},
		})
	end

	-- S A M P L E S
	-- -----------------------
	local function samples()
		if DLV.options.include_samples.value ~= true then return nil end
		--
		local sample_filenames = {}
		local path = DLV:get_path_for(Dlvrr.CONTEXT_SAMPLE)

		-- local sample_instruments = {}
		for i=1, #renoise.song().instruments do
			if #renoise.song():instrument(i).samples > 0 then
				local I = renoise.song():instrument(i)
				-- local save_path = DLV:normalize_path(DLV:sanitize_filename(I.name))
				for n=1, #I.samples do
					-- table.insert(sample_filenames, save_path..DLV:filename_sample(n, I, I.samples[n]))
					table.insert(sample_filenames, DLV:filename_sample(n, I, I.samples[n])..'.'..DLV.options.export_format_samples.value)
				end
				-- table.insert(sample_instruments, renoise.song():instrument(i))
			end
		end

		return wrap_section('Raw Samples', self.vb:column {
			multiline(path),
			-- self.vb:space {height=5},
			self.vb:row {
				text('Output Format:', 90),
				strong(string.upper(DLV.options.export_format_samples.value)),
			},
			self.vb:row {
				text('Filenames:', 90),
				multiline_strong( table.concat(sample_filenames, '\n'), 60 ),
			},
			-- self.vb:row {
				-- text('Save to:', 90),
				-- text(path),
			-- },
		})
	end

	-- Proceed
	-- --------------
	local content_view = self.vb:column {
		margin = 5,
		spacing = 5,
		width = WIDGET_WIDTH,
		self.vb:text {
			width = WIDGET_WIDTH-10,
			text = '- WARNING -\nEXISTING FILES WILL BE OVERWRITTEN',
			style = 'strong',
			font = 'bold',
			align = 'center',
		},
		self.vb:text {
			text = 'The following item(s) will be rendered/exported:',
			style = 'strong',
		},
		mixdown(),
		stems(),
		xrni(),
		samples(),
	}

	-- rprint({'ALL_OK?', self.deliverer:all_ok()})
	if self.deliverer:all_ok() ~= true then
		self:fail()
		do return end
	end

	local pressed = renoise.app():show_custom_prompt('The DELIVERER: Preflight Summary', content_view, {'OK', 'Cancel'})
	if pressed == 'OK' then
		self:run_render()
	end
end

-----------------------------------------------------------------------------

function DlvrrGui:show_summary()

	if self.deliverer:all_ok() == true then

		local function seconds_to_time (secs)
			secs = tonumber(string.format('%0.f', secs))
			local remainder
			local days_elapsed = math.floor(secs / 86400)
			remainder = (secs % 86400)
			local hours_elapsed = math.floor(remainder / 3600)
			remainder = (secs % 3600)
			local mins_elapsed = math.floor(remainder / 60)
			local secs_elapsed = (remainder % 60)

			local elapsed_time_table = {days=days_elapsed, hours=hours_elapsed, mins=mins_elapsed, secs=secs_elapsed}

			local elapsed = {}
			if days_elapsed > 0 then table.insert(elapsed, days_elapsed..' day') end
			if hours_elapsed > 0 then table.insert(elapsed, hours_elapsed..' hr') end
			if mins_elapsed > 0 then table.insert(elapsed, mins_elapsed..' min') end
			if secs_elapsed > 0 then table.insert(elapsed, secs_elapsed..' sec') end

			return table.concat(elapsed, ', '), elapsed_time_table
		end

		local elapsed_time = os.clock() - self.batch_start_time
		print('finished in '..elapsed_time..'s')
		self.progress_bar_batch.value = 1
		self.progress_bar.value = 1
		self.working_context.text = 'Batch processing'
		self.text_working_on.text = 'COMPLETE in '..seconds_to_time(elapsed_time)
		self.deliverer:set_status('Batch processing complete.')

		self.editing_enabled.value = true
	else
		self:fail()
	end
end

-----------------------------------------------------------------------------

function DlvrrGui:cancel_render()
	renoise.song():cancel_rendering()
	TASKER:cancel_all()
	self.working_context.text = 'Batch processing'
	self.text_working_on.text = 'CANCELLED'
	self.deliverer:set_status('Batch processing cancelled.')

	self.editing_enabled.value = true
end

-----------------------------------------------------------------------------

function DlvrrGui:fail()
	TASKER:cancel_all()
	renoise.song():cancel_rendering()
	self.working_context.text = 'Deliverer Failure'
	self.text_working_on.text = 'ERROR'

	self.vb.views.status_panel.visible = true
	self.editing_enabled.value = true
	
	self.deliverer.ok_status.value = true -- reset status
end


function DlvrrGui:open_token_key ()

	local content = self.vb:column{
		style = 'group',
		margin = self.SPACING,
	}
	for i=1, #self.acceptable_tokens do
		content:add_child(self.vb:row {
				self.vb:text {
					style = 'strong',
					text = '{'..self.acceptable_tokens[i][1]..'}',
					width = 105,
				},
				self.vb:text {
					text = self.acceptable_tokens[i][2],
				},
			})
	end
	renoise.app():show_custom_dialog('The DELIVERER: File Name Variables', content)
end


-- vim: foldenable:foldmethod=syntax:foldnestmax=1:foldlevel=0:foldcolumn=3
-- :foldopen=all:foldclose=all
