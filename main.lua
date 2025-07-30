--[[ 

	Keybindings Speed Bar
	------------
	Displays keybindings in a quick search "speed bar" based on user input.
	--
	DLT <dave.tichy@gmail.com>

	v1.0:
		* Maintain state when closed
		* Pass all non-alphanumeric characters/key commands directly back to Renoise
	
	v1.1:
		* Prioritize/limit results to window context
	
	TODO:
		* Ask user for permission to interrogate their Keybindings file (outside of tool folder)
	
--]]



local dialog = nil
local vb = nil




local DLT_SpeedBar = {}
function DLT_SpeedBar:new()
	local o = {
		PROMPT_TEXT = 'Type to search',
		QUERY = renoise.Document.ObservableString(''),
		DEBUG = renoise.Document.ObservableString(''),
		STATUS = renoise.Document.ObservableString(''),
		QUERY_CHANGED = renoise.Document.ObservableBang(),
		elements = {},
		matches = {},
		filter = function(results) return results end,
	}
	local mt = {__index = self}
	setmetatable(o, mt)
	return o
end


function DLT_SpeedBar:add_element ( search_string, element )
	-----------------------------
	local t = {
		str = search_string,
		el = element,
	}
	table.insert(self.elements, t)
end


function DLT_SpeedBar:set_query ( term )
	-----------------------------
	self.QUERY.value = term
	if term ~= self.PROMPT_TEXT then
		self:search()
	end
end


function DLT_SpeedBar:get_query ()
	-----------------------------
	return self.QUERY.value
end

function DLT_SpeedBar:clear()
	-----------------------------
	self.QUERY.value = self.PROMPT_TEXT
	self.STATUS.value = ''
	self.matches = {}
end

function DLT_SpeedBar:set_filter( callback )
	-----------------------------
	self.filter = callback
end

function DLT_SpeedBar:reset_filter()
	-----------------------------
	self.filter = nil
end

function DLT_SpeedBar:search ( )
	-----------------------------
	if self.QUERY.value == self.PROMPT_TEXT or self.QUERY.value == '' then
		self:clear()
		return {}
	end

	local t = os.clock() -- stats

	local pattern = self:get_search_regex()
	self.matches = {}
	for k,v in ipairs(self.elements) do
		if string.match(v.str, pattern) then
			table.insert(self.matches, v.el)
		end
		--
	end

	if self.filter ~= nil then
		self.matches = self.filter(self.matches)
	end

	self.STATUS.value = 'Found ' .. table.getn(self.matches) .. ' matches for "' .. self:get_query() .. '" in ' .. string.format('%5.3f s', (os.clock() - t) ) -- stats
	self.DEBUG.value = 'Pattern: '..pattern 
	-- stats
	return self.matches
end


function DLT_SpeedBar:get_search_regex ()
	-----------------------------
	local term = self:get_query()
	local chars = {}
	for i=1, string.len(term) do
		local az = term:sub(i, i)
		table.insert(chars, '['..az:lower()..az:upper()..']+')
	end
	return table.concat(chars, '.*')
end


function DLT_SpeedBar:keyhandler (dialog, key)
	-----------------------------
	-- In a speedbar, we want to completely capture all key input, not passing anything back to Renoise
	-- self.DEBUG.value = key.name

	local qlen = string.len(self.QUERY.value)

	--[[ Capture [escape] to control dialog ]]
	if key.name == 'esc' then
		if qlen > 0 and self.QUERY.value ~= self.PROMPT_TEXT then
			-- Escape empties the search term
			self:clear()
			self.QUERY_CHANGED:bang()
		else
			-- Escape from empty search closes the box
			dialog:close()
		end
		return nil -- totally capture

	--[[ Capture [backspace] to correct search term ]]  
	elseif key.name == 'back' then
		if qlen > 0 and self.QUERY.value ~= self.PROMPT_TEXT then
			self.QUERY.value = string.sub(self.QUERY.value, 1, qlen-1)
		end
		if self.QUERY.value == '' then
			self:clear()
		end
		self.QUERY_CHANGED:bang()
		return nil -- totally capture

	--[[ Capture alphanumerics (and shifted) for editing search term ]]
	elseif key.character and string.match(key.character , "[ A-Za-z0-9]+") and (key.modifiers == '' or key.modifiers == 'shift') then
		if self.QUERY.value == self.PROMPT_TEXT then
			self.QUERY.value = ''
		end
		self.QUERY.value = self.QUERY.value .. key.character
		self.QUERY_CHANGED:bang()
		return nil -- totally capture
	end

	--[[ Everything else gets passed through as entered ]]
	-- Close dialog on anything other than above keys?
	dialog:close()
	return key
end








--[[
--renoise.app().window.active_middle_frame 
--renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
--]]


local get_window_context_from_key = function( kb )
	local c = kb.Category
	local t = kb.Topic

	if c == 'Global' then
		return 'global'

	elseif c == 'Sample Editor' then
		return renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR

	elseif c == 'Sample Keyzones' then
		return renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_KEYZONES

	elseif c == 'Sample FX Mixer' then
		return renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS

	elseif c == 'Sample Modulation Matrix' then
		return renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION

	elseif c == 'Mixer' then
		return renoise.ApplicationWindow.MIDDLE_FRAME_MIXER

	elseif c == 'Pattern Editor'
		or c == 'Pattern Sequencer' 
		or c == 'Pattern Matrix' then
		return renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR

	elseif c == 'Phrase Editor' then
		return renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR

	elseif c == 'Phrase Map' then
		return renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR

	elseif c == 'Automation' 
		or c == 'DSP Chain'
		or c == 'Disk Browser' 
		or c == 'Instrument Box' then
		return 'global'

	end

	return nil
end




function filter_on_window_context( results )
	local coll = table.create()
	local AMF = renoise.app().window.active_middle_frame

	for n=1,table.getn(results) do
		local r = results[n]
		if r.WindowContext == 'global' or r.WindowContext == AMF then
			table.insert(coll, r)
		end
	end
	return coll
end




function populate_speedbar( SB_instance )
	-- TODO: Add a preference for permission to read this file (since it's outside of the Tools folder)
	local keyfile_path = renoise.tool().bundle_path .. '../../../'
	local keyfile = keyfile_path .. "KeyBindings.xml"

	-- Parse the keyboard shortcuts XML file 
	-- NOTE: Not using Renoise's Document:load_from() because it won't pull all fields from XML file into table :(
	-------------------------------------------------------
	local xml2lua = require "xml2lua"
	local handler = require("xmlhandler.tree")
	local parser = xml2lua.parser(handler)

	parser:parse(xml2lua.loadFile(keyfile))

	-- Let's put this in a format we can easily search
	-------------------------------------------------------
	for k,v in pairs(handler.root.KeyboardBindings.Categories) do
		for k2, v2 in pairs(v) do
			local cat = v2.Identifier
			local binds = v2.KeyBindings.KeyBinding or {}
			for k3, v3 in pairs(binds) do
				v3.Key = v3.Key or ''
				-- Include keybinding in search?
				-- local kb = v3.Binding..' '..cat..' '..v3.Topic..' '..' '..v3.Key -- description, category, topic, and actual key binding
				local kb = v3.Binding..' '..cat..' '..v3.Topic -- description, category, and topic
				-- local kb = v3.Binding -- only description
				v3.Category = cat
				v3.WindowContext = get_window_context_from_key(v3)
				SB_instance:add_element( kb, v3 )
			end
		end
	end

	-- Put in alphabetical order
	--table.sort(SB_SHORTCUTS)
end






--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------


local SB_options = renoise.Document.create("SpeedBarOptions") { 
	filter_on_context = renoise.Document.ObservableNumber(1),
}
renoise.tool().preferences = SB_options








-- Setup SpeedBar
local SB = DLT_SpeedBar:new()

-- Filter preferences
local set_display_filter_from_prefs = function()
	if SB_options.filter_on_context.value == 1 then
		SB:set_filter( filter_on_window_context )
	elseif SB_options.filter_on_context.value == 2 then
		SB:reset_filter()
	else
		SB:reset_filter()
	end
	-- trigger a UI update, etc
	SB.QUERY_CHANGED:bang()
end

set_display_filter_from_prefs()
SB_options.filter_on_context:add_notifier( set_display_filter_from_prefs )

-- fill with values from Keyfile
populate_speedbar( SB )





-- TODO: Break most of this out into a DLT_SpeedBarGui class

local function show_dialog()

	if dialog and dialog.visible then
		dialog:show()
		return
	end

	--------------------------
	
	vb = renoise.ViewBuilder()

	local WIDGET_WIDTH = 800
	local WIDGET_HEIGHT = 400
	local WIDGET_SPACING = 10
	local MAX_RESULTS_VISIBLE = 20

	--------------------------

	local query_input = vb:text {
		width = '100%',
		height = 40,
		text = SB.PROMPT_TEXT,
		style = 'strong',
		font = 'big',
	}

	local results_list = vb:multiline_text {
		id = 'results',
		height = WIDGET_HEIGHT,
		width = '100%',
		text = 'Results will appear here',
	}


	-- turn "Command + Shift + 9" into "⇧⌘9"
	local shorten_key_command = function (command)
		return command
		--[[
		local k = command
		-- TODO: Change for windows
		-- TODO: Meh.
		k = k:gsub('Command', '⌘')
		k = k:gsub('Option', '⌥')
		k = k:gsub('Option', '⌃')
		k = k:gsub('Shift', '⇧')
		k = k:gsub(' %+ ', '')
		return k
		--]]
	end


	local make_result_row = function (match, callback)
		callback = callback or function() return nil end
		
		local k_style, k_text
		if match.Key == '' then
			k_text = 'Unbound'
			k_style = 'disabled'
		else
			k_text = shorten_key_command(match.Key)
			k_style = 'strong'
		end

		return vb:row {
			style = 'body',
			vb:text {
				width = 200,
				text = match.Category..' : '..match.Topic,
			},
			vb:text {
				width = 350,
				font = 'bold',
				style = 'strong',
				text = match.Binding,
			},
			vb:text {
				width = 250,
				style = k_style,
				text = k_text,
			},
		}
	end


	local make_rowset = function()
		return vb:column {
			width = WIDGET_WIDTH,
			height = WIDGET_HEIGHT,
		}
	end

	local result_rows = make_rowset()

	local results_container = vb:column {
		width = WIDGET_WIDTH,
		height = WIDGET_HEIGHT,
		margin = WIDGET_SPACING,
		result_rows,
	}

	local status_text = vb:text {
		style = 'disabled',
		font = 'italic',
		width = 300,
		align = 'left',
		text = '',
	}

	local debug_text = vb:text {
		style = 'strong',
		font = 'italic',
		width = '100%',
		text = SB.DEBUG.value,
	}

	local update_results_list = function ()
		-- "empty" the container
		results_container:remove_child(result_rows)
		result_rows = make_rowset()
		results_container:add_child(result_rows)
		-- limit to N visible results
		local max_results = math.min(table.getn(SB.matches), MAX_RESULTS_VISIBLE)
		for i=1, max_results do
			local row = make_result_row(SB.matches[i])
			result_rows:add_child(row)
		end
	end

	local update_ui = function ()
		query_input.text = SB.QUERY.value
		if SB.QUERY.value == SB.PROMPT_TEXT then
			SB.matches = {}
		else
			SB:search()
		end
		update_results_list()
		status_text.text = SB.STATUS.value
		debug_text.text = SB.DEBUG.value
	end


	local content = vb:column {
		width = WIDGET_WIDTH,
		vb:column {
			style = 'plain',
			width = '100%',
			-- margin = WIDGET_SPACING,
			vb:horizontal_aligner {
				vb:space { width = WIDGET_SPACING },
				query_input,
			},
		},
		vb:space { height = WIDGET_SPACING/2 },
		vb:row {
			vb:space { width = WIDGET_SPACING },
			vb:horizontal_aligner {
				width = WIDGET_WIDTH,
				mode = 'justify',
				status_text,
				vb:popup {
					width = 150,
					items = {
						"Filter by current context",
						"Show All",
					},
					value = SB_options.filter_on_context.value,
					bind = SB_options.filter_on_context,
				},
			},
		},
		results_container,
		-- debug_text
	} 


	local keyhandler = function (d, k)
		return SB:keyhandler(d,k)
	end

	dialog = renoise.app():show_custom_dialog('Keybindings Speed Bar', content, keyhandler)  
	
	-- If we already have matches saved, re-show the last search results
	-- so the user can start from the same place
	if table.getn(SB.matches) > 0 then
		update_ui()
	end

		-- Update the UI if we've changed
	SB.QUERY_CHANGED:add_notifier( update_ui )
	-- Update the UI if we switch context
	renoise.app().window.active_middle_frame_observable:add_notifier( update_ui )
end




--[[ Keybinding/Menu Entry ]]
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
	name = "Global:Tools:Speed Bar...",
	invoke = show_dialog  
}

renoise.tool():add_menu_entry {
	name = "Main Menu:Tools:Speed Bar...",
	invoke = show_dialog  
}

