--------------------------------------------------------------------------------
-- Cells!
--
-- Copyright 2012 Martin Bealby
--
-- Instrument Manager Code
--------------------------------------------------------------------------------


--[[
InstrumentManager.cells_instruments[]
InstrumentManager.sliced_notes[]
InstrumentManager.instrument_names[]
InstrumentManager.renoise_instrument_list_cache
InstrumentManager:__init
InstrumentManager:RemoveHooks()
InstrumentManager:CreateInstrumentList()
InstrumentManager:CreateSlicedNotes(instrument_index)
InstrumentManager:GetInstrumentNames()
InstrumentManager:GetInstrumentInfo(name)
InstrumentManager:GetSlicedNotes(name)
InstrumentManager:SetTranspose(name, value)


cells_instruments table has the following structure:
  { instrument_name,
    instrument_index,
    transpose,  -- set samples in instrument all to the same as the first sample
    number_of_cells,
    { cell_name,
      cell_sample_index,
      cell_note_value,
      cell_length_frames,
      cell_length_lines,
      cell_is_looped,
      cell_is_slice,
      cell_slice_markers{},
      cell_playback_mode,

    }  <per cell>
  }  <per instrument>
]]--



--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class "InstrumentManager"



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function InstrumentManager:__init()
  -- Initialise
  self.cells_instruments = {}
  self.instrument_names = {}
  self.renoise_instrument_list_cache = {}

  -- Attach hooks
  if not renoise.song().instruments_observable:has_notifier(self, self.ChangeHook) then
    renoise.song().instruments_observable:add_notifier(self, self.ChangeHook)
  end

  -- Create initial list
  self:CreateInstrumentList(true)
end


function InstrumentManager:RemoveHooks()
  -- Remove hooks

  if renoise.song().instruments_observable:has_notifier(self, self.ChangeHook) then
    renoise.song().instruments_observable:remove_notifier(self, self.ChangeHook)
  end
end


function InstrumentManager:ChangeHook()
  -- Change hook function
  
  -- update list
  self:CreateInstrumentList(false)
  
  -- push out to channels
  for i = 1, preferences.channel_count.value do
    cc[i]:NewInstrumentList(self.instrument_names)
  end
end


function InstrumentManager:CreateInstrumentList(force_update)
  -- Completely update the instrument list and pushs it out to the CellsChannels if not starting
  
  local rs = renoise.song()
  local new_il = {}
  local new_names = {"None"}
  local inst
  local samp
  local map
  local inst_table = {}
  local cell_table = {}
  local meta_sliced_instrument = {}
  local valid_sample_maps = {}
  local new_cache = {}



  -- create a new cache
  for i = 1, #rs.instruments do
    table.insert(new_cache, rs.instruments[i].name)
  end
  
  -- compare and abort on no change if not forced   -- DOESN'T WORK TODO
  --[[
  if unpack(new_cache) == unpack(self.renoise_instrument_list_cache) then
    if not force_update then
      -- quick exit
      return
    end
  end
  ]]--
  
  -- reset sliced notes
  self.sliced_notes = {} 
  for i = 1, #rs.instruments do
    table.insert(self.sliced_notes, i, {})
  end

  -- update cache
  self.renoise_instrument_list_cache = new_cache
  
  for i = 1, #rs.instruments do
    -- iterate over all instruments
    
    -- reset flag
    valid_sample_maps = {}
    
    -- get reference
    inst = rs.instruments[i]
  
    for s = 1, #inst.sample_mappings[renoise.Instrument.LAYER_NOTE_ON] do
      -- check all sample maps for ones that point to valid samples
      map = inst:sample_mapping(renoise.Instrument.LAYER_NOTE_ON, s)
      
      if inst.samples[map.sample_index].sample_buffer.has_sample_data then
        if inst.samples[map.sample_index].autofade == false then        -- autofade = ignore
          table.insert(valid_sample_maps, s)
        end
      end
    end
    
    if #valid_sample_maps ~= 0 then
      -- there are some samples, parse the instrument     
      inst_table = {}
      --table.insert(new_names, #new_names+1, inst.name)    -- names list
      table.insert(new_names,  inst.name)    -- names list
      table.insert(inst_table, inst.name)                 -- instrument name
      table.insert(inst_table, i)                         -- instrument index
      table.insert(inst_table, math.max(-12,
                                        math.min(12,
                                                 inst.samples[1].transpose))) -- instrument transpose
      
      table.insert(inst_table, #valid_sample_maps)        -- cell count    
      
      -- create sliced loop notes if required
      if #inst.samples[1].slice_markers ~= 0 then
        self:CreateSlicedNotes(i)
      end
        
   
      for x = 1, #valid_sample_maps do
        -- parse each cell (sample map)
        cell_table = {}
        
        -- get references
        map = inst:sample_mapping(renoise.Instrument.LAYER_NOTE_ON, valid_sample_maps[x])
        samp = inst.samples[map.sample_index]
        
        if samp.autofade == false then  -- autofade = sample ignore
        
          if string.sub(samp.name, 1, 3) == "NT1" then
            table.insert(cell_table, notestring2name(samp.name))
          else
            table.insert(cell_table, samp.name)               -- sample name
          end
          table.insert(cell_table, map.sample_index)        -- sample index
          table.insert(cell_table, map.note_range[1])       -- trigger note
          table.insert(cell_table,                          -- length in seconds
                       samp.sample_buffer.number_of_frames)
          table.insert(cell_table, samp.beat_sync_lines)    -- length in lines
          if samp.loop_mode == renoise.Sample.LOOP_MODE_OFF then
            table.insert(cell_table, false)                 -- is looped
          else
            table.insert(cell_table, true)                  -- is looped
          end
          table.insert(cell_table, samp.is_slice_alias)     -- is a slice
          table.insert(cell_table, samp.slice_markers)      -- slice markers
    
          -- work out sample playback mode
          
          if samp.beat_sync_enabled then
            table.insert(cell_table, PLAYMODE_REPITCH)
            
          elseif string.sub(samp.name, 1, 3) == "NT1" then    -- magic note clip header
            table.insert(cell_table, PLAYMODE_NOTES)
              
            -- load notes
            self:AddSlicedNotes(i, x, notestring2table(samp.name))
              
          elseif #samp.slice_markers ~= 0 then
            table.insert(cell_table, PLAYMODE_NOTES)
             
          elseif samp.autoseek then
            table.insert(cell_table, PLAYMODE_GRANULAR)
          
          elseif samp.is_slice_alias then
            table.insert(cell_table, PLAYMODE_SLICES)
            
          else
            table.insert(cell_table, PLAYMODE_ONESHOT)
          end
                
          -- add to instrument
          table.insert(inst_table, cell_table)
        end
      end
            
      -- Add to instrument table
      table.insert(new_il, inst_table)
    end
  end
  
  -- Update main tables
  self.cells_instruments = new_il
  self.instrument_names = new_names
end


function InstrumentManager:AddSlicedNotes(instrument_index, cell_index, note_table)
  -- Inserts a pregenerated table of notes (from notestring2table into the note table cache

  table.insert(self.sliced_notes[instrument_index], cell_index, note_table)
end


function InstrumentManager:CreateSlicedNotes(instrument_index)
  -- Create the note pattern to play the sliced instrument in time
  
  -- Idea based upon dblue's slices to notes script
   
  local inst = renoise.song().instruments[instrument_index]
  local sample_mappings_count = #inst.sample_mappings[renoise.Instrument.LAYER_NOTE_ON]
  local samples = inst.samples
  local slice_count = #samples[1].slice_markers 
  local total_frames = samples[1].sample_buffer.number_of_frames
  local slice_frames = 0
  local total_lines = samples[1].beat_sync_lines
  local slice_lines = 0
  local fpl = total_frames / total_lines
  local note_table = {}
  local line = 0
  local fline = 0
  local note_delay = 0
  local tref = {}
  
  -- populate with empty tables
  for i = 1, total_lines do
    table.insert(note_table, i, {})
  end
  
  -- iterate over all slices, populating local note table
  for i = 1, slice_count do
    slice_frames = samples[i+1].sample_buffer.number_of_frames
    slice_lines = slice_frames / fpl
    
    fline = math.floor(line)
    
    -- calculate delay
    note_delay = math.floor((line - fline) * 256)
    
    -- handle multiple notes on the same row
    if i+1 <= sample_mappings_count then
      table.insert(note_table[fline+1], {inst:sample_mapping(renoise.Instrument.LAYER_NOTE_ON, i+1).note_range[1],
                                         127, -- max vol
                                         note_delay})
    end
    
    -- next slice
    line = line + slice_lines
  end

  table.insert(self.sliced_notes[instrument_index], 1, note_table)
end


function InstrumentManager:GetInstrumentNames()
  -- Return a table of valid instrument names
  return self.instrument_names
end


function InstrumentManager:GetInstrumentInfo(inst_name)
  -- Return a instrument info
  
  for i = 1, #self.cells_instruments do
    if self.cells_instruments[i][1] == inst_name then
      return self.cells_instruments[i]
    end
  end
 
  -- not there anymore
  return "Removed"
end


function InstrumentManager:GetSlicedNotes(inst_name, index)
  -- Return the (precalculated) sliced loop note equivalent
  
  local i = self:InstrumentNameToIndex(inst_name)
  

  if i then
    -- found
    return self.sliced_notes[i][index]
  end
  
  -- not valid
  return {}
end


function InstrumentManager:SetTranspose(inst_name, value)
  -- Set the transpose of all samples in the instrument
  
  local i = self:InstrumentNameToIndex(inst_name)
  
  if not i then
    return
  end

  local inst = renoise.song().instruments[i]
 
  if inst.samples[1].transpose ~= math.floor(value) then
    for i = 1, #inst.samples do
      inst.samples[i].transpose = math.floor(value)
    end
  end
end


function InstrumentManager:InstrumentNameToIndex(inst_name)
  -- Returns the lua instrument index from an instrument name
  
  for i = 1, #renoise.song().instruments do
    if renoise.song().instruments[i].name == inst_name then
      return i
    end
  end
  
  return false
end
