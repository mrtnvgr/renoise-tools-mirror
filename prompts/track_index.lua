--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Track Index Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'TrackIndexPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function TrackIndexPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_TRACK_IDX

  -- display index
  if renoise.song().selected_track.type == renoise.Track.TRACK_TYPE_MASTER then
    set_lcd("mst", true)
  else
    set_lcd(string.format("t%02x", renoise.song().selected_track_index), true)
  end
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function TrackIndexPrompt:encoder(delta)
  -- encoder change
  local rs = renoise.song()
  local i = clamp(rs.selected_track_index+delta,
                  1, #rs.tracks)
                  
  rs.selected_track_index = i
end


function TrackIndexPrompt:func_x()
  -- insert
  local rs = renoise.song()
  
  local new = rs:insert_track_at(rs.selected_track_index+1)
  rs.selected_track_index = rs.selected_track_index + 1
  BasePrompt.func_x(self)
end


function TrackIndexPrompt:func_y()
  -- delete
  local rs = renoise.song()
  
  -- cannot delete master track
  if rs.selected_track.type == renoise.Track.TRACK_TYPE_MASTER then
    return
  end
  
  -- too few track
  if #rs.tracks <= 2 then
    return
  end
  
  rs:delete_track_at(rs.selected_track_index)
  BasePrompt.func_y(self)
end


function TrackIndexPrompt:func_z()
  -- clear pattern track
  local rs = renoise.song()
  
  rs.selected_pattern.tracks[rs.selected_track_index]:clear()
  BasePrompt.func_z(self)
end
