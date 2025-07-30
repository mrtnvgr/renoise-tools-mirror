 --[[------------------------------------------------------------------------------------
  
  AutoColors
  
  Automatically sets track colors by track names, using regular expression filters.
  E.g. you can assign a filter "^.*hat$" to a RGB color value. All track names which
  end with a "hat" string will have the same color.
  
  The basic idea of this tool was taken from SWS Reaper extensions
  
  Copyright 2012 Matthias Ehrmann, 
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License. 
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 

  Unless required by applicable law or agreed to in writing, software distributed 
  under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
  CONDITIONS OF ANY KIND, either express or implied. See the License for the specific 
  language governing permissions and limitations under the License.
  
  TODO: improve performance to find mst. See GlobalMidiActions.lua
    
--------------------------------------------------------------------------------------]]--

-- data structure for color map entries
class "AutoColorsMapEntry"(renoise.Document.DocumentNode)

function AutoColorsMapEntry:__init()

  -- important! call super first
  renoise.Document.DocumentNode.__init(self)

  self:add_properties {
    filters = { "" },
    color = {0xff,0xff,0xff},
    color_blend = 20
  }
  
end

-- main class 
class "AutoColors"

-- includes and outsourced stuff
require "Debug"
require "Helpers"

-- constructor for initializations on application level 
-- nothing song specific is initialized in here
function AutoColors:__init()

  TRACE("__init()")

  -- member variables
  
  self.config_name = "config"
  self.config_ext = "xml"
  self.config_path = self.config_name.."."..self.config_ext 
 
  -- preferences 
  
  self.prefs = renoise.Document.create("AutoColorPreferences") {          
    color_map = renoise.Document.DocumentList()
  }    
  self.prefs.color_map:insert(renoise.Document.create("AutoColorsMapEntry") {
    filters = { "" }, color= {0xff,0xff,0xff}, color_blend = 20 
  })  
  --self.prefs:save_as(self.config_path)   -- just for tests
  if (io.exists(self.config_path)) then  
    local success, errmsg = self.prefs:load_from(self.config_path)  
    if (not success) then
      -- remove dummy (explanation see below)
      self.prefs.color_map:remove()
    end
  else
    -- remove dummy entry, which is implicitly needed
    -- for structure description and loading of preferences, 
    -- but can be removed, if no prefs are available
    self.prefs.color_map:remove()
  end

  -- tool registration  
  
  renoise.tool():add_menu_entry {
    name = "Main Menu:View:AutoColors Filters",
    invoke = function() self:toggle_filter_dialog() end,
    selected = function() return self:filter_dialog_visible() end
  }

  renoise.tool():add_keybinding {
    name = "Global:Tools:Show AutoColor Filters",
    invoke = function() self:toggle_filter_dialog() end,
    selected = function() return self:filter_dialog_visible() end
  }  

  renoise.tool():add_midi_mapping {
    name = "Global:Tools:Show AutoColor Filters [Trigger]",
    invoke =  function(message) 
                if (message:is_trigger()) then
                  self:toggle_filter_dialog() 
                end
              end,
    selected = function() return self:filter_dialog_visible() end
  }  
  
  -- add new song observer
  if (not renoise.tool().app_new_document_observable:has_notifier(
    self,self.on_song_created)) then
    renoise.tool().app_new_document_observable:add_notifier(
      self,self.on_song_created)
  end
  
   -- add song pre-release observer  
  if (not renoise.tool().app_release_document_observable:has_notifier(
    self,self.on_song_pre_release)) then
    renoise.tool().app_release_document_observable:add_notifier(
      self,self.on_song_pre_release)
  end
       
  -- dialogs 'n views
  local vb = renoise.ViewBuilder()
  self.filter_dialog = nil
  local filter_dialog_width = 350
  
  self.filter_list = 
    vb:multiline_textfield {
        text = "",
        width = filter_dialog_width,
        height = 500,        
    }      
    
  self.filter_view = 
    vb:column {
      margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
      spacing = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
      self.filter_list
    }
  self:update_filter_view()
  
  if (not self.prefs.color_map:has_notifier(
    self,self.on_update_filter_list)) then
    self.prefs.color_map:add_notifier(
      self,self.on_update_filter_list)
  end
end

function AutoColors:add_track_name_changed_notifier(track)

  TRACE("add_track_name_changed_notifier()")

  if (not track.name_observable:has_notifier(
    self,self.on_track_name_changed)) then
    track.name_observable:add_notifier(
      self,self.on_track_name_changed)               
  end
end

function AutoColors:remove_track_name_changed_notifier(track)

  TRACE("remove_track_name_changed_notifier()")
 
  if (track.name_observable:has_notifier(
    self,self.on_track_name_changed)) then
    track.name_observable:remove_notifier(
      self,self.on_track_name_changed) 
  end
end

-- song created handler
-- reset member variables and register notifiers
function AutoColors:on_song_created()
  
  TRACE("on_song_created()")
  
  if (not song().tracks_observable:has_notifier(
    self,self.on_tracks_changed)) then
    song().tracks_observable:add_notifier(
      self,self.on_tracks_changed)
  end
    
  for t = 1,#song().tracks do          
    self:on_tracks_changed({type = "insert", index = t})    
  end  
end

-- song pre release handler
-- this is called right before the song is being released
function AutoColors:on_song_pre_release()

  TRACE("on_song_pre_release()")      
  -- TODO free listeners ? Guess this is automatically done by Renoise    
end

function AutoColors:on_tracks_changed(notification)

  TRACE("on_tracks_changed()")

  if (notification.type == "insert") then
    self:add_track_name_changed_notifier(song().tracks[notification.index])  
    
    -- force "has changed"
    self:on_track_name_changed()
  
  elseif (notification.type == "remove") then  
    self:remove_track_name_changed_notifier(song().tracks[notification.index])
    
    -- force "has changed"
    self:on_track_name_changed()        
  end  
end
  
function AutoColors:on_track_name_changed() 
  
  TRACE("on_track_name_changed()")
    
  -- since we don't know the source track index
  -- we have to iterate over all tracks.
  -- This is not nice, but there's no better solution
  for t = 1,#song().tracks do      
   
    local args = song().tracks[t].name
     
    ------------------------------------------------------------
    -- handle commands
    -- these commands modify the filters / color mapping list
     
    -- add filter
    if (args:find("^add:.*$")) then
   
      local filters = self:get_filters(song().tracks[t],string.sub(args,5))
      for f = 1,#filters do      
        if (not self:add_filter(song().tracks[t], filters[f])) then
          return -- error: don't apply filters
        end
      end
      
    -- remove filter
    elseif (args:find("^rem:.*$")) then
    
      -- iterate over all tracks and
      -- remove ALL matching filters
      local filters = self:get_filters(song().tracks[t],string.sub(args,5))  
      for f = 1,#filters do
        if (not self:remove_filter(song().tracks[t], filters[f])) then
          return 
        end          
      end
      return -- don't apply filters
      
    -- update color of single filter
    elseif (args:find("^upd:.*$")) then
    
      local filters = self:get_filters(song().tracks[t],string.sub(args,5))  
      for f = 1,#filters do      
        if (not self:update_filter(song().tracks[t], filters[f])) then
          return -- error: don't apply filters 
        end
      end
      
    -- update color of group of filters
    elseif (args:find("^upg:.*$")) then
    
      local filter = string.sub(args,5)
      if (not self:update_group(song().tracks[t], filter)) then
        return -- error: don't apply filters 
      end
    
    -- reset all filters
    elseif (args:find("^reset:$")) then
    
      self:reset_filters(song().tracks[t])
      return -- don't apply filters
      
    -- save all filters (save as)
    elseif (args:find("^save:.*$")) then
      
      local alt_name = string.sub(args,6)
      self:save_filters(song().tracks[t],alt_name)
      return -- don't apply filters      
      
    -- load all filters
    elseif (args:find("^load:.*$")) then
   
      local alt_name = string.sub(args,6)
      if (not self:load_filters(song().tracks[t], alt_name)) then
        return -- error don't apply filters
      end
      
    -- list all filters
    elseif (args:find("^lst:$")) then          
    
      self:list_filters(song().tracks[t])
      return -- don't apply filters
      
    end
  end
   
  self:apply_filters()    
end


-- iterate over all tracks/trackanmes and apply filters
function AutoColors:apply_filters()

  TRACE("apply_filters()")
  
  for t = 1,#song().tracks do        
    local name = song().tracks[t].name:lower() 
    for i = 1,#self.prefs.color_map do
      for j = 1,#self.prefs.color_map[i].filters do
        local pattern = (self.prefs.color_map[i].filters[j].value)
        if (name:find(pattern)) then     
          song().tracks[t].color = 
            { self.prefs.color_map[i].color[1].value, 
              self.prefs.color_map[i].color[2].value, 
                self.prefs.color_map[i].color[3].value}
          song().tracks[t].color_blend = self.prefs.color_map[i].color_blend.value         
        end   
      end   
    end
  end
end

-- searches for a specific filter pattern in the filter / colormap list
-- found: returns color_map_index,filter_list_index
-- not found: returns nil
function AutoColors:find_filter(filter)

  TRACE("find_filter()")

  -- check if filter is empty
  if (filter == "") then
    return false
  end
  
  local filter_lower = filter:lower()  
  for i = 1,#self.prefs.color_map do
    for j = 1,#self.prefs.color_map[i].filters do
      local pattern = (self.prefs.color_map[i].filters[j].value)
      if (filter_lower == pattern) then     
          return i,j
      end   
    end
  end    
  return nil
end

-- return index, or nil if not found
function AutoColors:find_color(color, color_blend)
  
  TRACE("find_color()")
    
  for i = 1,#self.prefs.color_map do  
    local cb = color_blend
    local cb1 = self.prefs.color_map[i].color_blend.value        
    if (cb == cb1) then
      if (self.prefs.color_map[i].color[1].value == color[1]) then        
        if (self.prefs.color_map[i].color[2].value == color[2]) then
          if (self.prefs.color_map[i].color[3].value == color[3]) then                
            return i
          end
        end
      end
    end          
  end   
  return nil  
end

-- add filter
-- return true: filter added
-- return false: no filter given, filter already exists, or io error  
function AutoColors:add_filter(track,filter)   

  TRACE("add_filter()")

  -- check if filter is empty
  if (filter == "") then
    self:print_feedback_msg(track, "NO FILTER")
    return false
  end

  -- check if filter already exists
  if (self:find_filter(filter) ~= nil) then
    self:print_feedback_msg(track, "EXISTS")
    return false
  end

  -- check if color already exists
  local index = self:find_color(track.color,track.color_blend)
  if (index ~= nil) then
    self.prefs.color_map[index].filters:insert(filter)
    self:on_update_filter_list()
  else
    -- create new color map entry
    self.prefs.color_map:insert(renoise.Document.create("AutoColorsMapEntry") {
      filters = { filter:lower() }, color = track.color, color_blend = track.color_blend
    })
  end
    
  -- save prefs
  local success,errmsg = self:save_prefs()
  if (success) then  
    self:print_feedback_msg(track,filter)  
  else
      self:print_feedback_msg(track,errmsg)  
     return false
  end 
  return true 
end

-- convenience wrapper which combines remove / add
-- update color of a single filter
-- return true: update ok
-- return false: update error
function AutoColors:update_filter(track,filter)   

  TRACE("update_filter()")  
  
  if (self:remove_filter(track,filter)) then
    self:add_filter(track,filter)  
    return true
  else
    return false
  end 
end

-- update color of a filter group
-- return true: update ok
-- return false: update error
function AutoColors:update_group(track, filter)

  TRACE("update_group()")
  
  -- check if filter already exists
  local i,j = self:find_filter(filter)
  if (i == nil) then
    self:print_feedback_msg(track, "NOT FOUND")
    return false
  else    
    self.prefs.color_map[i].color[1].value = track.color[1]
    self.prefs.color_map[i].color[2].value = track.color[2]
    self.prefs.color_map[i].color[3].value = track.color[3]
    self.prefs.color_map[i].color_blend.value = track.color_blend
    self:on_update_filter_list()
    self:print_feedback_msg(track,filter)  
  end
  return true
end  

-- iterate over all filter entries and remove all matching filters
-- return true: filter removed
-- return false: no filter given, not found or io error
function AutoColors:remove_filter(track,filter)   

  TRACE("remove_filter()")
  
  -- check if filter is empty
  if (filter == "") then  
    self:print_feedback_msg(track,"NO FILTER")  
    return false
  end
      
  local filter_lower = filter:lower()
  local found = false
  for i = 1,#self.prefs.color_map do
    for j = 1,#self.prefs.color_map[i].filters do
      if (filter_lower == self.prefs.color_map[i].filters[j].value) then
        found = true
        self.prefs.color_map[i].filters:remove(j)        
        if (#self.prefs.color_map[i].filters <= 0) then
          self.prefs.color_map:remove(i)
        end       
        break
      end
    end
    if (i >= #self.prefs.color_map) then
      break
    end
  end  
  self:update_filter_view()
  
  if (found) then   
    local success,errmsg = self:save_prefs()
    if (not success) then
      self:print_feedback_msg(track,errmsg)  
      return 
    end      
    self:print_feedback_msg(track,"REMOVED")
    return true
  end
  self:print_feedback_msg(track,"NOT FOUND")
  return false
end

-- reset (remove) all filters
-- return true: ok
-- return false: io error
function AutoColors:reset_filters(track)

  TRACE("reset_filters()")

  for i = 1,#self.prefs.color_map do
    self.prefs.color_map:remove()        
  end 
  local success,errmsg = self:save_prefs()     
  if (success) then
    self:print_feedback_msg(track,"RESET")
  else
    self:print_feedback_msg(track,errmsg)          
    return false
  end
  return true
end

-- save all filters into another xml document
-- name is: config_<alt_name>.xml
-- if the name already exists, the existing
-- document is moved into config_<alt_name>.xml.back
-- return true: everythink ok
-- return false: io error, or empty alt_name
function AutoColors:save_filters(track,alt_name)

  TRACE("save_filters()")
  
  if (alt_name ~= "") then      
    local config_path_alt = self.config_name.."_"..alt_name.."."..self.config_ext        
    if (io.exists(config_path_alt)) then        
      local success, errmsg = 
        os.move(config_path_alt,config_path_alt..".back")
      if (not success) then
        self:print_feedback_msg(track,errmsg) 
        return false
      end
    end
    
    local success,errmsg = self.prefs:save_as(config_path_alt)
    if (not success) then
      self:print_feedback_msg(track,errmsg)
      return false
    end  
  else
    self:print_feedback_msg(track,"NO NAME")
    return false
  end
    self:print_feedback_msg(track,"SAVED")
  return true
end

-- load all filters from another xml document
-- name is: config_<alt_name>.xml
-- return true: everythink ok
-- return false: not found, io error, or empty alt_name
function AutoColors:load_filters(track,alt_name)
  
  TRACE("load_filters()")

  if (alt_name == "") then      
    self:print_feedback_msg(track,"NO NAME")
    return false
  end
  
  local config_path_alt = self.config_name.."_"..alt_name.."."..self.config_ext        
  if (io.exists(config_path_alt)) then        
    local success,errmsg = self.prefs:load_from(config_path_alt)          
    if (not success) then
      self:print_feedback_msg(track,errmsg)
      return false
    end  
  else
    self:print_feedback_msg(track,"NOT FOUND")
    return false
  end
  
  self:print_feedback_msg(track,"LOADED") 
  return true
end

-- return -> [success, error_string or nil on success]
function AutoColors:save_prefs()

  TRACE("save_prefs()")
  
  -- if exists do a backup of the old config file
  if (io.exists(self.config_path)) then  
    os.move(self.config_path,self.config_path..".back")
  end
  
  -- create a new one
  return self.prefs:save_as(self.config_path)
end 

-- print feedback message in the name input field of a track
-- thereby switch notification temporarily off to avoid feedback loop      
function AutoColors:print_feedback_msg(track,message)

  TRACE("print_feedback_msg()")

  self:remove_track_name_changed_notifier(track)    
  track.name = message   
  self:add_track_name_changed_notifier(track)
end


-- THIS FUNCTION WAS TAKEN FROM http://lua-users.org/wiki/SplitJoin
-- It's not part of the above mentioned Apache License !
--[[ written for Lua 5.1
split a string by a pattern, take care to create the "inverse" pattern 
yourself. default pattern splits by white space.
]]
string.split = function(str, pattern)
  pattern = pattern or "[^%s]+"
  if pattern:len() == 0 then pattern = "[^%s]+" end
  local parts = {__index = table.insert}
  setmetatable(parts, parts)
  str:gsub(pattern, parts)
  setmetatable(parts, nil)
  parts.__index = nil
  return parts
end

-- helper function
function AutoColors:get_filters(track,args)
  if (args == "") then 
    self:print_feedback_msg(track,"EMPTY")
    return { }
  else
    return args:split("[^,%s]+")
  end
end

-- toggle filter list dialog
function AutoColors:list_filters(track)

  TRACE("list_filters()")
  
  if (not self:filter_dialog_visible()) then
    self:print_feedback_msg(track, "SHOW")  
  else
    self:print_feedback_msg(track, "HIDE")
  end  
  self:toggle_filter_dialog()
end

-- filter dialog handler
function AutoColors:toggle_filter_dialog()

  TRACE("toggle_filter_dialog()")

  if (self:filter_dialog_visible()) then
    self.filter_dialog:close()
  else
    if (self.filter_view) then
      self:update_filter_view()
      self.filter_dialog = 
        renoise.app():show_custom_dialog("AutoColors Filters", self.filter_view)  
    end
  end
end

-- indicates if filter dialog is visible/valid
function AutoColors:filter_dialog_visible()

  TRACE("filter_dialog_visible()")

  return self.filter_dialog and self.filter_dialog.visible
end

-- called whenever the color map has changed
function AutoColors:on_update_filter_list()

  TRACE("on_update_filter_list()")
  
  if (self:filter_dialog_visible()) then
    self:update_filter_view()
  end
end

-- updates datat/text of filter view (child views)
function AutoColors:update_filter_view()
  
  TRACE("update_filter_view()")
  
  self.filter_list.text = "[ R, G, B ]   [BLEND %] <- FILTERS\n"..
                          "````````````````````````````````````````````````````````````````\n"
  
  if (#self.prefs.color_map <= 0) then
    self.filter_list.text = self.filter_list.text..">> NO FILTERS DEFINED ! <<\n"    
  else
    for i = 1,#self.prefs.color_map do
    
      local cm = self.prefs.color_map[i]
    
      self.filter_list.text = self.filter_list.text..
        string.format("%s%X,%X,%X%s%d%s ",
          "[",cm.color[1].value,cm.color[2].value,cm.color[3].value,"]   [", 
            cm.color_blend.value,"%] <- ")
              
      for j = 1,#self.prefs.color_map[i].filters do        
          self.filter_list.text = self.filter_list.text..cm.filters[j].value.." "
      end
      self.filter_list.text = self.filter_list.text.."\n"
    end    
  end
  
  local help = "\nCOMMANDS - enter them in any track's name input field:\n".. 
               "````````````````````````````````````````````````````````````````\n"..              
               "add:<regex>[,<regex>,..]    add new filter(s)\n"..
               "rem:<regex>[,<regex>,..]    remove filter(s)\n"..               
               "upd:<regex>[,<regex>,..]    update color of single filter(s)\n"..
               "upg:<regex>                 update color of a filter's group\n"..               
               "lst:                        show/hide this dialog\n\n"..
               "reset:                     reset = remove all filters\n"..
               "save:<name>       save all filters into xml file\n"..
               "load:<name>        load all filters from xml file\n\n"..
               
               "REGULAR EXPRESSIONS:\n"..
               "````````````````````````````````````````````````````````````````\n"..
               "CHARS:    ^ start     $ end    . any     ? 0..1      * 0..n      + 1..n\n".. 
               "                 %d digit      %d2 two digits\n"..
               " SETS:   [123] any    [a-z] range    [^123] neg set\n\n"..                             
               " HINT: filter matching works always case-insensitive !\n\n"..
                              
               "````````````````````````````````````````````````````````````````\n"..
               "EXAMPLES:\n\n"..  
               "add:snare     add:^kick[123]$,bd[123]   ^.*drum     synth.+  \n\n"..
               "More info:  http://lua-users.org/wiki/PatternsTutorial\n\n"..
               "(c) 2012, M. Ehrmann"
    
  self.filter_list.text = self.filter_list.text..help
end  
