-----------------------------------------------------------------------------
--▓█████▄  ██▓  ▄▄▄█████▓  ██▓███   ██▀███  ▓█████   ██████ ▓█████▄▄▄█████▓  ██████
--▒██▀ ██▌▓██▒  ▓  ██▒ ▓▒ ▓██░  ██▒▓██ ▒ ██▒▓█   ▀ ▒██    ▒ ▓█   ▀▓  ██▒ ▓▒▒██    ▒
--░██   █▌▒██░  ▒ ▓██░ ▒░ ▓██░ ██▓▒▓██ ░▄█ ▒▒███   ░ ▓██▄   ▒███  ▒ ▓██░ ▒░░ ▓██▄
--░▓█▄   ▌▒██░  ░ ▓██▓ ░  ▒██▄█▓▒ ▒▒██▀▀█▄  ▒▓█  ▄   ▒   ██▒▒▓█  ▄░ ▓██▓ ░   ▒   ██▒
--░▒████▓ ░██████▒▒██▒ ░  ▒██▒ ░  ░░██▓ ▒██▒░▒████▒▒██████▒▒░▒████▒ ▒██▒ ░ ▒██████▒▒
-- ▒▒▓  ▒ ░ ▒░▓  ░▒ ░░    ▒▓▒░ ░  ░░ ▒▓ ░▒▓░░░ ▒░ ░▒ ▒▓▒ ▒ ░░░ ▒░ ░ ▒ ░░   ▒ ▒▓▒ ▒ ░
-- ░ ▒  ▒ ░ ░ ▒  ░  ░     ░▒ ░       ░▒ ░ ▒░ ░ ░  ░░ ░▒  ░ ░ ░ ░  ░   ░    ░ ░▒  ░ ░
-- ░ ░  ░   ░ ░   ░       ░░         ░░   ░    ░   ░  ░  ░     ░    ░      ░  ░  ░
--   ░        ░  ░                    ░        ░  ░      ░     ░  ░              ░
-- ░
-----------------------------------------------------------------------------
--  ___  ____ ____ ____ ____ ___    _  _ ____ _  _ ____ ____ ____ ____
--  |__] |__/ |___ [__  |___  |     |\/| |__| |\ | |__| | __ |___ |__/
--  |    |  \ |___ ___] |___  |     |  | |  | | \| |  | |__] |___ |  \
--     v 0.8
---------------------------------------------------------------------------
--[[ LICENSE |
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
-------------------------------------------------------------------------]]
--[[ CHANGELOG |
	v0.8:
	----
		- Decouple factory presets from user presets for saving/loading XML files


	KNOWN BUGS:
	----------------
		- 

	Someday / Maybe:
	----------------
		- [Medium] Add support for preset versions, with auto-upgrading
		- [Low] Add support for "magic" presets (for per-song settings?)

]]
--[[ USAGE |
-----------------------------------------------------------------------------

Usage:

Interact with presets via the Dlt_PresetList.

	Step 1. DEFINE YOUR PRESET CLASS

	Create a class for your preset type that inherits Dlt_Preset, like so:

		class 'MyHotPresetType' (Dlt_Preset)
		function MyHotPresetType:__init(opts)
			Dlt_Preset.__init(self, opts)
		end

	Now define the "model" for your preset data by setting initial values in a "default_properties" table. This will be fed into a renoise.Document.DocumentNode:add_properties(), so elements will automatically become observable.

		MyHotPresetType._version = 1
		MyHotPresetType.default_properties = {
			gain = 18,
			distortion = 100,
			crush_value = 11,
			take_prisoners = false,
			path = 'no/return/'
		}


	Step 2. INTEGRATE INTO YOUR TOOL

	Now that your preset class and model are defined, add something like this into your class' __init() or otherwise before handling any data or building any GUI elements:

	Here, self.options is the class member that will hold our "presettable" fields. We initialize it with our hot new preset type.

		self.options = MyHotPresetType()

	Define some factory presets

		local FACTORY_PRESETS = {}
		table.insert(FACTORY_PRESETS, {_name = 'Default',})
		table.insert(FACTORY_PRESETS, {_name = 'Low Gain', gain = -3, distortion = 20})

	Now init the preset manager, which fills with factory presets

		self.presets = Dlt_PresetList(MyHotPresetType, self.options, FACTORY_PRESETS)
		self.presets:load_all()


	Step 3. PROFIT

	To load a preset:

		self.presets:load_preset(last_loaded_id)
		etc...

--]]


--===========================================================================
--     ___  _    ___     ___  ____ ____ ____ ____ ___ _    _ ____ ___
--     |__> |___  |  ___ |--' |--< |=== ==== |===  |  |___ | ====  |
--
--     P R E S E T   L I S T   C L A S S
-----------------------------------------------------------------------------

class 'Dlt_PresetList' (renoise.Document.DocumentNode)

-----------------------------------------------------------------------------
-- @param (string) preset_model - The Preset class name to be called when building new presets (ex: Dlt_Preset)
-- @param (renoise.Document.DocumentNode) context - the node in which to load a selected preset, and from which to build new presets (ex: self.options). This is the Preset element in your caller that holds the presettable options
-- @param (table) factory_presets - A table holding an array of factory preset tables. Each may be a simple table.

function Dlt_PresetList:__init (preset_model, context, factory_presets)

	self.filename = 'presets.xml'
	
	self.FACTORY_PRESETS = factory_presets or {}
	self.PRESET_MODEL = preset_model -- Dlt_Preset
	self.CONTEXT = context

	-- important! call super first
	renoise.Document.DocumentNode.__init(self)

	self:add_properties {
		presets = renoise.Document.DocumentList(),
		selected_preset_index = 1,
		current = nil,
	}

	-- if #self.FACTORY_PRESETS > 0 then
		-- self:build_factory_presets()
	-- end

	-- Debugging
	-- self.presets:add_notifier(function(what) rprint(what) end)
end

-----------------------------------------------------------------------------

function Dlt_PresetList:set_context (context)
	self.CONTEXT = context
end

-----------------------------------------------------------------------------

function Dlt_PresetList:load_all ()
	-- print('loading presets from '..self.filename)

	if #self.FACTORY_PRESETS > 0 then
		self:build_factory_presets()
	end

	local user_presets = Dlt_PresetList(self.PRESET_MODEL, nil, {})
	user_presets:load_from(self.filename)
	if #user_presets.presets > 0 then
		-- print('loading '..#user_presets.presets..' user preset(s)')
		for i=1, #user_presets.presets do
			local preset = user_presets.presets[i]
			self:insert_preset(preset._name.value, preset)
		end
	end

	-- rprint(#self.presets)
--
end

-----------------------------------------------------------------------------

function Dlt_PresetList:save_all ()
	local user_presets = Dlt_PresetList(self.PRESET_MODEL, nil, {})
	-- user_presets.presets = {}
	-- Decouple user presets from factory presets
	for i=1, #self.presets do
		local preset = self.presets[i]
		if preset.is_factory_preset.value == false then
			user_presets:insert_preset(preset._name.value, preset)
		end
	end
	user_presets:save_as(self.filename)
	-- self:save_as(self.filename)
end

-----------------------------------------------------------------------------

function Dlt_PresetList:get_all ()
	return self.presets
end
-- Dlt_Preset:save_as(file_name)
-- Dlt_Preset:load_from (filename)

-----------------------------------------------------------------------------

function Dlt_PresetList:get_preset (idx)
	return self.presets[idx]
end

-----------------------------------------------------------------------------

function Dlt_PresetList:load_preset (idx)
	if idx > #self.presets then
		idx = 1
	end
	-- return self:get_preset(idx)
	local preset = self:get_preset(idx)
	if preset then
		self.selected_preset_index.value = idx
		-- print('loading preset: '..preset._name.value)
		preset:load_into(self.CONTEXT)
	end
end

-----------------------------------------------------------------------------
-- insert a new preset

function Dlt_PresetList:insert_preset (preset_name, context)
	context = context or self.CONTEXT
	context._name.value = preset_name

	local preset = self:build_preset(context)
	preset._name.value = preset_name
	preset.is_modified.value = false

	local insert_point = self:get_insert_point(preset_name)
	self.presets:insert(insert_point, preset)

	return insert_point
end

function Dlt_PresetList:new_preset (preset_name, context)
	
	local insert_point = self:insert_preset(preset_name, context)

	self:load_preset(insert_point)
	self:save_all()
end

-----------------------------------------------------------------------------
-- overwrite an existing preset at given index

function Dlt_PresetList:update_preset (idx, context)
	context = context or self.CONTEXT
	if not self.presets[idx].is_read_only.value then
		context:load_into(self.presets[idx])
		self:save_all()
	end
end

-----------------------------------------------------------------------------
-- overwrite an existing preset at given index

function Dlt_PresetList:delete_preset(idx)
	if not self.presets[idx].is_read_only.value then
		self.presets:remove(idx)
		local show_idx = idx
		if show_idx > #self.presets then
			show_idx = #self.presets
		end
		self.selected_preset_index.value = show_idx
		self:save_all()
	end
end

-----------------------------------------------------------------------------

function Dlt_PresetList:rename_preset (idx, name)
	if not self.presets[idx].is_read_only.value then
		local new_pos = self:get_insert_point(name)
		new_pos = math.min(new_pos, #self.presets)
		self.presets[idx]._name.value = name
		self.presets:swap(idx, new_pos)
		self.selected_preset_index.value = new_pos
		self:save_all()
	end
end

-----------------------------------------------------------------------------
-- get insert point for new presets by name

function Dlt_PresetList:get_insert_point (name, self_idx)
	local insert_point = #self.presets + 1
	for i=1, #self.presets do
		local p = self.presets[i]
		-- avoid read-only (factory) presets
		-- case-sensitive
		-- if (p.is_magic_preset.value == false and p.is_factory_preset.value == false) and p._name.value > name then
		-- case-insensitive
		if (p.is_magic_preset.value == false and p.is_factory_preset.value == false) and p._name.value:lower() > name:lower() then
			return i
		end
  end
	return insert_point
end


function Dlt_PresetList:build_preset (preset_data)
	return self.PRESET_MODEL(preset_data)
end

-----------------------------------------------------------------------------

function Dlt_PresetList:build_factory_presets ()

	-- print('building '..#self.FACTORY_PRESETS..' factory presets')
	local i,p
	for i=1, #self.FACTORY_PRESETS do

		p = self:build_preset(self.FACTORY_PRESETS[i])
		p._name.value = self.FACTORY_PRESETS[i]._name
		p.is_read_only.value = true
		p.is_factory_preset.value = true
		i = self:get_insert_point(p._name.value)
		self.presets:insert(i, p)
	end
end



--===========================================================================
--     C O N T E X T U A L   " M A G I C "   P R E S E T S
-----------------------------------------------------------------------------

class 'Dlt_ContextualPreset'
function Dlt_ContextualPreset:__init (context, key, preset_idx)
	self.context = context
	self.key = key
	self.preset_idx = preset_idx
end


class 'Dlt_ContextualPresetList' (renoise.Document.DocumentNode)
function Dlt_ContextualPresetList:__init (preset_class)
	renoise.Document.DocumentNode.__init(self)
	self.CONTEXTUAL_PRESET = preset_class or Dlt_ContextualPreset
	self.context = 'song'
	self.filename = 'presets_contextual.xml'
	self:add_properties({
		presets = renoise.Document.DocumentList(),
	})
end

function Dlt_ContextualPresetList:set_context (context)
	self.context = context
end

function Dlt_ContextualPresetList:find (key)
	for i=1, #self.presets do
		if self.presets[i].context == self.context and self.presets[i].key == key then
			return self.presets[i].preset_idx
		end
	end
	return nil
end

function Dlt_ContextualPresetList:insert (key, preset_idx)
	self.presets:insert( self.CONTEXTUAL_PRESET(self.context, key, preset_idx) )
	self.presets:save_as(self.filename)
end




--===========================================================================
--     ___  _    ___     ___  ____ ____ ____ ____ ___
--     |__> |___  |  ___ |--' |--< |=== ==== |===  |
--
--     P R E S E T   C L A S S
-----------------------------------------------------------------------------

class 'Dlt_Preset' (renoise.Document.DocumentNode)

function Dlt_Preset:__init (opts, preset_version)
	-- important! call super first
	renoise.Document.DocumentNode.__init(self)

	self.preset_version = preset_version or 1

	self.is_loading = false

	-- These properties' values will apply to all new created presets
	self:add_properties({
		is_factory_preset = false, -- whether preset is a factory preset
		is_read_only = false, -- whether preset shouldn't be overwritten
		is_magic_preset = false, -- whether preset is a 'magic'/ethereal preset (won't get saved to presets.xml, stored somewhere else)
		is_modified = false,
		_name = 'Untitled Preset',
		_version = self.preset_version,
	})

	if not self.default_properties then
		-- print('Dlt_Preset: NO DEFAULT PROPERTIES SET')
		self.default_properties = {}
	end

	self:add_properties(self.default_properties)


	if opts then
		self:populate(opts)
	end


	local function mark_dirty()
		if not self.is_loading then
			self.is_modified.value = true
		end
	end

	-- Make any changes mark the preset as dirty
	for k,v in pairs(self.default_properties) do
		self[k]:add_notifier(mark_dirty)
	end

	if self._version.value ~= self.preset_version then
		local from_version = self._version.value
		local to_version = self.preset_version
		self:upgrade_preset(from_version, to_version)
	end
end

-----------------------------------------------------------------------------

function Dlt_Preset:load_into (dest)

	self.is_loading = true
	dest.is_loading = true
	local dest_object = dest
	for k,v in pairs(self.default_properties) do
		dest_object[k].value = self[k].value
	end
	self.is_modified.value = false
	dest_object.is_modified.value = false
	self.is_loading = false
	dest.is_loading = false

end

-----------------------------------------------------------------------------

function Dlt_Preset:upgrade_preset (from_version, to_version)
	print('Dlt_Preset: [NOTICE]: Some or all user presets need to be upgraded. An upgrade_preset() method must be defined in your preset class.')
	-- This is a stub. Implement this for your own preset types based on your needs.
	-- Recurse over it until your presets are up to date
end

-----------------------------------------------------------------------------

function Dlt_Preset:populate (data)
	-- Simple table?
	if type(data) == 'table' then
		for k,v in pairs(data) do
			self[k].value = v
		end
	elseif type(data) == type(self) then
		-- Or Preset model?
		data:load_into(self)
	end

	self.is_modified.value = false
end

-----------------------------------------------------------------------------

function Dlt_Preset:is_dirty ()
	return self.is_modified.value
end




--===========================================================================
--     ___  _    ___     ___  ____ ____ ____ ____ ___ ____ _  _ _
--     |__> |___  |  ___ |--' |--< |=== ==== |===  |  |__, |__| |
--
--     P R E S E T   G U I   C L A S S
-----------------------------------------------------------------------------
-- In your GUI code, initialize the preset gui class before building your GUI
--
--   local preset_gui = Dlt_PresetGui(self.vb, self.dlt_presets_instance)
--
-- Then run:
--   preset_gui:preset_picker( picker_width )
--
-- to return the smart ViewBuilder object containing the preset picker GUI.
-----------------------------------------------------------------------------

class 'Dlt_PresetGui'

function Dlt_PresetGui:__init (ViewBuilder_instance, PresetList_instance, factory_preset_prefix)
	self.vb = ViewBuilder_instance
	self.presets = PresetList_instance
	self.factory_preset_prefix = factory_preset_prefix or 'Factory Preset: '
	self.use_icons_for_buttons = false
	self.viewbuilder_view_id = 'dlt_preset_picker'
end

-----------------------------------------------------------------------------

function Dlt_PresetGui:update_preset_picker ()

	local presets = self.presets:get_all()
	local preset_list = {}
	local i = 0

	local picked = self.presets.selected_preset_index.value

	for i=1, #presets do
		local name = presets[i]._name.value
		local preset = presets[i]

		if preset.is_read_only.value == true then
			name = self.factory_preset_prefix .. name
		end
		-- if we're looking at a preset loaded into current gui, then interrogate
		-- that one
		if picked == i then
			if self.presets.CONTEXT:is_dirty() then
				name = '* '..name .. ' (modified)'
			end

			if preset.is_read_only.value == true then
				self.vb.views.preset_save_button.active = false
				self.vb.views.preset_rename_button.active = false
				self.vb.views.preset_delete_button.active = false
				-- print('deactivated buttons')
			else
				if self.presets.CONTEXT:is_dirty() then
					self.vb.views.preset_save_button.active = true
				else
					self.vb.views.preset_save_button.active = false
				end
				self.vb.views.preset_rename_button.active = true
				self.vb.views.preset_delete_button.active = true
				-- print('activated buttons')
			end

		end

		preset_list[i] = name
	end
	-- local add_preset_index = #preset_list + 1
	-- preset_list[add_preset_index] = 'Create new preset...'
	self.vb.views.preset_picker_popup.items = preset_list
	if picked <= #presets then
		self.vb.views.preset_picker_popup.value = picked
	end
end

-----------------------------------------------------------------------------

function Dlt_PresetGui:preset_picker (panel_width, picker_width)

	local panel_width = panel_width or '100%'
	local picker_width = picker_width or 300
	local icon_button_width = 25

	-- notifier callbacks
	local save_notifier = function()
		local picked = self.vb.views.preset_picker_popup.value
		local to_replace = self.presets:get_preset(picked)
		if to_replace.is_read_only.value == true then
			self:preset_prompt_for_save('Copy of '..to_replace._name.value)
		else
			self.presets:update_preset(picked)
		end
	end
	local saveas_notifier = function()
		self:preset_prompt_for_save()
	end
	local delete_notifier = function()
		local picked = self.vb.views.preset_picker_popup.value
		local p = self.presets:get_preset(picked)
		self:preset_confirm_delete(picked, p._name.value)
	end
	local rename_notifier = function()
		local picked = self.vb.views.preset_picker_popup.value
		local p = self.presets:get_preset(picked)
		self:preset_prompt_for_rename(picked, p._name.value)
	end


	local save_button, saveas_button, rename_button, delete_button

	if self.use_icons_for_buttons == true then
		-- USE ICONS for buttons
		save_button = self.vb:button {
			id = 'preset_save_button',
			width = icon_button_width,
			bitmap = 'img/dlt_presets_icon_save.bmp',
			-- text = '✎',
			tooltip = 'Save changes to preset',
			notifier = save_notifier
		}
		saveas_button = self.vb:button {
			id = 'preset_save_as_button',
			width = icon_button_width,
			bitmap = 'img/dlt_presets_icon_add.bmp',
			tooltip = 'Save as new preset',
			notifier = saveas_notifier
		}
		delete_button = self.vb:button {
			id = 'preset_delete_button',
			width = icon_button_width,
			bitmap = 'img/dlt_presets_icon_delete.bmp',
			tooltip = 'Delete preset',
			notifier = delete_notifier
		}
		rename_button = self.vb:button {
			id = 'preset_rename_button',
			width = icon_button_width,
			bitmap = 'img/dlt_presets_icon_edit.bmp',
			tooltip = 'Rename preset',
			notifier = rename_notifier
		}


	else
		-- USE TEXT for buttons
		save_button = self.vb:button {
			id = 'preset_save_button',
			text = 'Save',
			tooltip = 'Save changes to preset',
			notifier = save_notifier
		}
		saveas_button = self.vb:button {
			id = 'preset_save_as_button',
			text = 'Save As...',
			tooltip = 'Save as new preset',
			notifier = saveas_notifier
		}
		delete_button = self.vb:button {
			id = 'preset_delete_button',
			text = 'Delete',
			tooltip = 'Delete preset',
			notifier = delete_notifier
		}
		rename_button = self.vb:button {
			id = 'preset_rename_button',
			text = 'Rename...',
			tooltip = 'Rename preset',
			notifier = rename_notifier
		}
	end

	local picker = self.vb:column {
		id = self.viewbuilder_view_id,
		style = 'plain',
		width = panel_width,
		self.vb:horizontal_aligner {
			mode = 'justify',
			self.vb:popup {
				id = 'preset_picker_popup',
				width=picker_width,
				items = {' ', ' '},
				value = 1,
				notifier = function()
					local picked = self.vb.views.preset_picker_popup.value
					-- print('Loading preset from picker')
					self.presets:load_preset(picked)
				end
			},
			self.vb:row {
				save_button,
				saveas_button,
				delete_button,
				rename_button,
			},
		},
	}
	self:update_preset_picker()
	self.presets.presets:add_notifier(function() self:update_preset_picker() end)
	self.presets.CONTEXT.is_modified:add_notifier(function()
		self:update_preset_picker()
	end)
	self.presets.selected_preset_index:add_notifier(function() self:update_preset_picker() end)
	return picker

end

-----------------------------------------------------------------------------
function Dlt_PresetGui:preset_prompt_for_rename (idx, name)

	-- is_modified state carries even when renamed, so this isn't strictly
	-- necessary?
	
	-- if self.presets.CONTEXT.is_modified.value == true then
		-- local content_view = self.vb:text {
			-- width = 200,
			-- text = 'You have unsaved changes. Do you want to save the preset first?',
		-- }
		-- local pressed = renoise.app():show_custom_prompt('Save changes first?', content_view, {'Yes', 'No'})
		-- if pressed == 'Yes' then
			-- self.presets:update_preset(idx)
		-- end
	-- end

	name = name or 'Untitled'..os.date(' (%Y-%m-%d %H:%M)')
	local preset_name = self.vb:textfield {
		width = 200,
		text = name,
		edit_mode = true,
	}
	local content_view = self.vb:row {
		self.vb:text {
			width = 70,
			text = 'Preset Name:',
		},
		preset_name,
	}
	local pressed = renoise.app():show_custom_prompt('Rename preset', content_view, {'OK', 'Cancel'})
	if pressed == 'OK' then
		self.presets:rename_preset(idx, preset_name.text)
	end

end

-----------------------------------------------------------------------------

function Dlt_PresetGui:preset_prompt_for_save (name)

	name = name or 'Untitled'..os.date(' (%Y-%m-%d %H:%M)')
	local preset_name = self.vb:textfield {
		width = 200,
		text = name,
		edit_mode = true,
	}
	local content_view = self.vb:row {
		self.vb:text {
			width = 70,
			text = 'Preset Name:',
		},
		preset_name,
	}
	local pressed = renoise.app():show_custom_prompt('Create new preset', content_view, {'OK', 'Cancel'})
	if pressed == 'OK' then
		self.presets:new_preset(preset_name.text)
	end

end

-----------------------------------------------------------------------------

function Dlt_PresetGui:preset_confirm_delete (idx, name)

	local content_view = self.vb:column {
		width = 300,
		margin = 5,
		self.vb:text {
			text = 'Are you sure you want to delete this preset?'
		},
		self.vb:text {
			style='strong',
			text = name,
		},
		self.vb:text {
			text = '\nThis action cannot be undone.'
		}
	}
	local pressed = renoise.app():show_custom_prompt('Really delete preset?', content_view, {'Yes', 'No'})
	if pressed == 'Yes' then
		self.presets:delete_preset(idx)
	end

end



-- vim: foldenable:foldmethod=syntax:foldnestmax=1:foldlevel=0:foldcolumn=3
-- :foldopen=all:foldclose=all
