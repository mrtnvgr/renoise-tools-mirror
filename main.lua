--[[============================================================================
Track Comments

Author: Florian Krause <siebenhundertzehn@gmail.com>
Version: 0.8
============================================================================]]--

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()
  
end

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

local current_song = nil

--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

-- Replace an index in the song comments
local function replace_index(index1, index2, pos)
  local comments = current_song.comments
  local start = table.find(comments, "... Comments Track " .. index1 .. " ...", pos)
  if start ~= nil then
    table.remove(comments, start)
    table.insert(comments, start, "... Comments Track " .. index2 .. " ...")
  end
  current_song.comments = comments
  return start
  
end

-- Delete a track comment from the song comments
local function delete_comment(track_index)
  local comments = current_song.comments
  local start = table.find(comments, "... Comments Track " .. track_index .. " ...")
  if start ~= nil then
    local ending = table.find(comments, "...", start)
    for old_line = start,ending+1 do
      table.remove(comments, start)
    end 
  end
  current_song.comments = comments
end
     

-- Order entries in global song comments
local function order_comments()
  local comments = current_song.comments
  local array = {}
  local beginning = #comments 
  for track=1,#current_song.tracks do
    local tmp = {}
    local start = table.find(comments, "... Comments Track " .. tostring(track) .. " ..." )   
    if start ~= nil then  
      if start < beginning then
        beginning = start
      end      
      local ending = table.find(comments, "...", start)      
      for i=start,ending do
        table.insert(tmp, comments[i])
      end      
      table.insert(array, track, tmp)     
    end    
  end  
  for i=beginning,#comments do
    table.remove(comments, beginning)
  end  
  for k,v in pairs(array) do  
    for _,entry in ipairs(array[k]) do
      table.insert(comments, entry)
    end    
    table.insert(comments, "")    
  end  
  table.remove(comments, #comments)
  current_song.comments = comments  
end

-- Update the track indices (in case tracks were inserted, deleted or swapped)
local function update_track_indices(event) 
  local comments = current_song.comments 
  
  -- Handle insert track
  if event['type'] == "insert" then
    print("INSERTED")
    for track=#current_song.tracks-1, event['index'], -1 do
       replace_index(track, track+1, 1)
    end
  end  
  
  -- Handle delete track
  if event['type'] == "remove" then
    print("REMOVED")
    delete_comment(event['index'])
    for track=event['index']+1 ,#current_song.tracks do
      print(track)
      replace_index(track, track-1, 1)
    end
  end  
  
  -- Handle swap two tracks
  if event['type'] == "swap" then
    print("SWAPPED")
    local pos = replace_index(event['index1'], event['index2'], 1)
    if pos ~= nil then
      replace_index(event['index2'], event['index1'], pos+1)
    else
      replace_index(event['index2'], event['index1'], pos)
    end
  end    
  order_comments()  
end

-- Update all track names
local function update_track_names()
  for track_index=1,#current_song.tracks do
    local start = table.find(current_song.comments, "... Comments Track " .. track_index .. " ...")
    if start ~= nil then
      local comments = current_song.comments
      comments[start+1] = "... " .. current_song.tracks[track_index].name .. " ..."
      current_song.comments = comments
    end
  end
end

-- Add notifiers to eeach track in song
local function add_notifier_to_tracks()
  for track=1,#current_song.tracks do
    current_song.tracks[track].name_observable:add_notifier(
    function()
      print("Name changed")
      update_track_names()
    end
    )
  end
end

-- When loading: Add curernt_song, add notifiers to each track and to tracks[]
renoise.tool().app_new_document_observable:add_notifier(
function()
  current_song = renoise.song()
  add_notifier_to_tracks()
  renoise.song().tracks_observable:add_notifier(
  function(event)
    print("Order changed")
    update_track_indices(event)
  end
  )
end
)

-- Get the track comments
local function get_comments(track_index)
  local comment = ""
  local start = table.find(current_song.comments, "... Comments Track " .. track_index .. " ...")
  if start ~= nil then
    local ending = table.find(current_song.comments, "...", start)
    local first_line = start+2
    local last_line = ending-1
    for comment_line = first_line,last_line do
      comment = comment .. current_song.comments[comment_line]
      if comment_line ~= last_line then
        comment = comment .. "\n"
      end
    end
  end  
  return comment  
end

-- Split string into array (split at newline)
local function lines(str)
  local t = {}
  local function helper(line)
    table.insert(t, line)
    return ""
   end
  helper((str:gsub("(.-)\r?\n", helper))) 
  return t  
end

-- Look where to put the track comment into the song comments
local function find_position(track_index)
  for track=track_index+1,#current_song.tracks do
    local start = table.find(current_song.comments, "... Comments Track " .. track_index .. " ...")
    if start ~= nil then
      return start
    end
  end  
  return nil  
end

-- Update the track comments
local function update_comments(track_index)
  local text = vb.views.text_field.text
  local array = lines(text)
  local comments = current_song.comments
  local start = table.find(comments, "... Comments Track " .. track_index .. " ...")
  if start ~= nil then
    local ending = table.find(comments, "...", start)
    local first_line = start+2
    local last_line = ending-1
    for old_line = first_line,last_line do
      table.remove(comments, first_line)
    end
    for v = #array,1,-1 do
      table.insert(comments, first_line, array[v])
    end
  else
    local position = find_position(track_index)
    if position == nil then
      position = #comments+1
    end
    table.insert(comments, position, "")
    local first_line = position+1
    table.insert(comments, first_line-1, "... Comments Track " .. tostring(current_song.selected_track_index) .. " ...")
    table.insert(comments, first_line, "... " .. current_song.tracks[track_index].name .. " ...")
    for v = #array,1,-1 do
      table.insert(comments, first_line+1, array[v])
    end
    table.insert(comments, first_line+#array+1, "...")
  end
  current_song.comments = comments  
end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()
  
  -- This block makes sure a non-modal dialog is shown once.
  -- If the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end
  
  -- The ViewBuilder is the basis
  vb = renoise.ViewBuilder()
  
  -- The title of the dialog
  local track_index_string = tostring(current_song.selected_track_index)
  local track_name = current_song.tracks[current_song.selected_track_index].name
  local title = "Comments for Track " .. track_index_string .. " (" .. track_name .. ")"
  -- The content of the dialog, built with the ViewBuilder.
  local content = vb:column {
    margin = 3,
    vb:multiline_textfield {
      id = "text_field",
      width = 300,
      height = 200,
      text = get_comments(current_song.selected_track_index),
      notifier = function()
        update_comments(current_song.selected_track_index)
      end
    }
  } 
  
  -- A custom dialog is non-modal and displays a user designed
  -- layout built with the ViewBuilder.   
  dialog = renoise.app():show_custom_dialog(title, content)  
  
end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Track:"..tool_name.."...",
  invoke = show_dialog  
}


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------


renoise.tool():add_keybinding {
  name = "Pattern Editor:Track:" .. tool_name.."...",
  invoke = show_dialog
}
