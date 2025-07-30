--[[============================================================================
main.lua
============================================================================]]--

local dialog = nil
local rns = nil
local vb = renoise.ViewBuilder()
local disable_ui_notifications = false

--_AUTO_RELOAD_DEBUG = function() end

local selected_tag = nil
local ADD_TAG_TEXT = "Add tag(s)..."

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value


--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

local function get_comment()
  return rns.selected_instrument.comments 
end

local function set_comment()
  rns.selected_instrument.comments = vb.views.txt_comments.paragraphs
end

local function set_tag(idx,str)
  local tags = rns.selected_instrument.tags
  for k,v in ipairs(tags) do
    if (v == str) then
      print("Tag already present...")
      return
    end
  end
  tags[idx] = str
  rns.selected_instrument.tags = tags
end

local function delete_tag(idx)
  local tags = rns.selected_instrument.tags
  table.remove(tags,idx)
  rns.selected_instrument.tags = tags
  if (selected_tag == idx) then
    selected_tag = nil
  end
end

local get_tag_button_id = function(idx)
  return string.format("instr_tags_%d",idx)
end

local function edit_tag(idx)

  local tag = vb.views[get_tag_button_id(idx)]
  local view = vb.views.edit_prompt
  if not view then
    view = vb:column {
      id = "edit_prompt",
      margin = 10,
      width = "100%",
      vb:textfield{
        id = "edit_tag",
        width = "100%",
      }
    }
  end
  vb.views.edit_tag.text = tag.text

  local choice = renoise.app():show_custom_prompt(
    "Edit tag",view,{"Update tag","Delete tag","Cancel"})

  if (choice == "Update tag") then
    set_tag(idx,vb.views.edit_tag.text)
    return true
  elseif (choice == "Delete tag") then
    delete_tag(idx)
    return true
  end

  return false

end

local function select_tag(idx)
  local tag = nil
  if selected_tag and selected_tag ~= idx then
    tag = vb.views[get_tag_button_id(selected_tag)]
    tag.color = {0x00,0x00,0x00}
  end
  tag = vb.views[get_tag_button_id(idx)]
  tag.color = {0xff,0xff,0xff}
  selected_tag = idx
end

local function update_tags()
  local tags = rns.selected_instrument.tags
  local row = vb.views.instr_tags_container
  local tag_idx = 1

  local tag_button = vb.views[get_tag_button_id(tag_idx)]
  while tag_button do
    row:remove_child(tag_button)
    vb.views[get_tag_button_id(tag_idx)] = nil
    tag_idx = tag_idx + 1
    tag_button = vb.views[get_tag_button_id(tag_idx)]
  end

  if table.is_empty(tags) then
    row:add_child(vb:text {
      id = "instr_tags_1",
      text = "No tags defined",
    })
  else
    for tag_idx = 1,#tags do
      row:add_child(vb:button {
        id = get_tag_button_id(tag_idx),
        text = tags[tag_idx],
        released = function()
          if (selected_tag ~= tag_idx) then
            select_tag(tag_idx)
          else
            if (edit_tag(tag_idx)) then
              update_tags()
            end
          end
        end
      })
    end 
  end

end

local function update_all()
  vb.views.txt_instr_name.text = string.format("Title: %s",rns.selected_instrument.name)
  disable_ui_notifications = true
  vb.views.txt_comments.paragraphs = get_comment()
  disable_ui_notifications = false
  update_tags()
end

-- Add a new tag (for multiple tags, separate with comma..)
local function add_tag(str)

  if string.find(str,",") then
    for str_tag in string.gmatch(str, '([^,]+)') do
      add_tag(str_tag)
    end
    return
  end

  local tags = rns.selected_instrument.tags
  for k,v in ipairs(tags) do
    if (v == str) then
      print("Tag already present...")
      return
    end
  end
  tags[#tags+1] = str
  rns.selected_instrument.tags = tags
  update_tags()
end

function attach_to_song()
  rns = renoise.song()
  renoise.song().selected_instrument_observable:add_notifier(function()
    update_all()
  end)
end

--------------------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  if dialog then
    attach_to_song()
    update_all()
  end
end)

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function reset_pending_tag()
  disable_ui_notifications = true
  vb.views.pending_tag.text = ADD_TAG_TEXT
  disable_ui_notifications = false
end

local function show_dialog()

  -- If the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end

  attach_to_song() 

  -- unregister viewbuilder controls with IDs
  if vb.views.txt_instr_name then
    vb.views.txt_instr_name = nil
    vb.views.instr_tags_container = nil
    vb.views.pending_tag = nil
    vb.views.txt_comments = nil

    local tag_idx = 1
    local tag_button = vb.views[get_tag_button_id(tag_idx)]
    while tag_button do
      vb.views[get_tag_button_id(tag_idx)] = nil
      tag_idx = tag_idx + 1
      tag_button = vb.views[get_tag_button_id(tag_idx)]
    end

  end

  local content = vb:column {
    margin = 4,
    vb:text {
      id = "txt_instr_name",
      text = "Hello world!"
    },
    vb:row {
      margin = 4,
      style = "group",
      vb:row {
        id = "instr_tags_container",
      },
      vb:textfield {
        id = "pending_tag",
        text = ADD_TAG_TEXT,
        notifier = function()
          if disable_ui_notifications then
            return
          end
          local pending_tag = vb.views.pending_tag
          add_tag(pending_tag.value)
          if renoise.tool():has_timer(reset_pending_tag) then
            renoise.tool():remove_timer(reset_pending_tag)
          end
          renoise.tool():add_timer(reset_pending_tag,100)
        end
      },
    },
    vb:row {
      style = "group",
      vb:multiline_textfield {
        id = "txt_comments",
        text = "",
        font = "mono",
        height = 200,
        width = 410,
        notifier = function()
          if disable_ui_notifications then
            return
          end
          set_comment()
        end
      }
    }
  } 

  local keyhandler = function(dlg,key)
    rprint(key)
    if (key.name == "del") and selected_tag then
      delete_tag(selected_tag)
      update_tags()
    end
  end
  
  dialog = renoise.app():show_custom_dialog("Instrument Info", content, keyhandler)  

  update_all()

end



--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Instrument Box:"..tool_name.."...",
  invoke = show_dialog  
}


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

--[[
renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = show_dialog
}
--]]


--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = show_dialog
}
--]]
