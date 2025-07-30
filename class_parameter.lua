--==================================================--
-- Class: Parameter
--==================================================--

class 'Parameter'

  function Parameter:__init(tbl)
    self.id = assert(tbl.id, "Parameter.id is missing")
    self.name = assert(tbl.name, "Parameter.name is missing")
    self.type = tbl.type  -- "sysex", "cc", "nrpn", "pitchbend"
    if (self.type ~= "pitchbend") then
      self.number = assert(tbl.number, "Parameter.number is missing (" .. self.id .. ")")
    end
    self.value = nil
    self.lsb_number = tbl.lsb_number -- Todo...
    self.default_value = tbl.default_value
    self.min_value = tbl.min_value
    self.max_value = tbl.max_value
    self.display_min_value = tbl.display_min_value
    self.display_max_value = tbl.display_max_value
    self.display_value_factor = 1
    self.randomize_min = tbl.randomize_min
    self.randomize_max = tbl.randomize_max    
    self.items = tbl.items
    self.item_values = tbl.item_values
    self.gui_type = tbl.gui_type
    self.sysex_message_template = tbl.sysex_message_template
    self.value_callback = tbl.value_callback

    if self.items then
      assert(self.min_value == nil, "Don't set min_value for switches this will be set automatically (" .. self.id .. ")")
      assert(self.max_value == nil, "Don't set max_value for switches this will be set automatically (" .. self.id .. ")")
    end

    if (self.type == nil) then self.type = "sysex" end
    if (self.min_value == nil) then 
      if (self.items ~= nil) then 
        self.min_value = 1 
      else
        self.min_value = 0 
      end
    end
    if (self.max_value == nil) then
      if (self.type == "pitchbend") then
        self.max_value = 16383
        self.display_max_value = 100
        self.display_min_value = -100
      elseif self.items ~= nil then
        self.max_value = #self.items
      else
        self.max_value = 127
      end
    end
    if (self.default_value == nil) then 
      if (self.type == "pitchbend") then
        self.default_value = 8192
      elseif (self.items ~= nil) then 
        self.default_value = 1
      else
        self.default_value = self.min_value
      end
    end
    
    if (self.items ~= nil) then 
      assert(self.default_value > 0, "Error in synth definition: default value for a switch/dropdown cannot be less than 1")
    end
    
    if self.display_min_value == nil then
      self.display_min_value = self.min_value
    end
    if self.display_max_value == nil then
      self.display_max_value  = self.max_value
    end

    -- Display value factor = factor for recalculating the sliders display value 
    -- which may be other than the actual/midi/patch value
    local display_range = self.display_max_value - self.display_min_value
    local actual_range = self.max_value - self.min_value
    self.display_value_factor = display_range / actual_range 

    self.patch_document_variable = nil
    self.midi_mapping_id = nil
    self.has_changed = false
    self.synth_definition = nil
    self.is_updating_value = false
  end
  
  --== Set up reference to synth definition, create patch document, add midi mappings, set sysex message start ==--
  function Parameter:initialize(synth_definition, sysex_message_template)
    if (self.sysex_message_template == nil) then
      self.sysex_message_template = sysex_message_template
    end
    self.synth_definition = synth_definition
    self.synth_definition.parameters[self.id] = self
    self.midi_mapping_id = self.synth_definition.midi_mapping_prefix .. self.id
    local patch_document = self.synth_definition.patch_document
    self.patch_document_variable = patch_document:add_property(self.id, self.default_value)
    self.value = self.patch_document_variable.value
    if self.synth_definition.omit_nrpn_lsb and self.type == "nrpn" then
      assert(self.max_value <= 127, "Error in synth definition: max value for nrpn parameter cannot be more than 127 if omit_nrpn_lsb is set")      
    end
    if self.randomize_min ~= nil or self.randomize_max ~= nil then
      self.synth_definition.has_randomize_values = true
    end 
  end

  function Parameter:add_midi_mappings(replace_existing)
    if renoise.tool():has_midi_mapping(self.midi_mapping_id) and replace_existing then --"Take over" the midi mapping
      print("Removing midi mapping:" .. self.midi_mapping_id)
      renoise.tool():remove_midi_mapping(self.midi_mapping_id)
    end
    if not renoise.tool():has_midi_mapping(self.midi_mapping_id) then --Only add midi mapping for the first instance of a synth
      --print("Adding midi mapping:" .. self.midi_mapping_id)
      renoise.tool():add_midi_mapping{
        name = self.midi_mapping_id,
        invoke = function(message)
          self:handle_midi_mapping_message(message)
        end
      }
    end
  end

  function Parameter:set_changed()
    self.synth_definition:set_changed()
  end  
  
  --== Handle incoming renoise midi mapping message  ==--
  function Parameter:handle_midi_mapping_message(message)
    local value = message.int_value
        
    if (self.items ~= nil) then --== this is a switch parameter ==--
      if (self.item_values ~= nil) then --== switch parameter has values for items ==--
        local out_value = 1
        for k,v in ipairs(self.item_values) do --== translate value to index of switch item ==--
          if (value >= v) then
            out_value = k
          else
            break
          end
        end
        value = out_value
      else
        value = value + 1 --== switch parameter sysex value defaults to 0, 1, 2, translate to 1, 2, 3 for viewbuilder switch ==--
        if (value > #self.items - 1) then value = #self.items end --== Make sure it does not exceed switch items ==--
      end
    end
    
    self:set_value(value)
    self:set_changed()

  end
  
  -- Set value - update UI - send midi
  function Parameter:set_value(value)
    local display_value = self:actual_value_to_display_value(value)
    print(("#Set value# param = %s actual = %s display = %s"):format(self.id,value,display_value))
    self.is_updating_value = true
    value = math.floor(value+0.5)
    self.value = value
    self.patch_document_variable.value = value
    local vb = self.synth_definition.view_builder
    local ui_element = vb.views[self.id]
    if ui_element ~= nil and type(ui_element) ~= "Button" then
      ui_element.value = display_value
    end
    local ui_valuefield = vb.views["valuefield_" .. self.id]
    if ui_valuefield ~= nil then
      ui_valuefield.value = display_value
    end    
    if not self.synth_definition.is_loading then
      self:send_midi()
    end
    self.is_updating_value = false
  end

  -- Set value from Ui element (maybe not real value...)
  function Parameter:ui_set_value(display_value)
    if self.is_updating_value then 
      return
    end
    self.is_updating_value = true
    local value = self:display_value_to_actual_value(display_value)
    print(("#UI set value# param = %s display = %s actual = %s"):format(self.id,display_value,value))
    self:set_changed()
    self.value = value
    self.patch_document_variable.value = value
    local vb = self.synth_definition.view_builder
    local ui_valuefield = vb.views["valuefield_" .. self.id]
    if ui_valuefield ~= nil then
      ui_valuefield.value = display_value
    end
    self:send_midi()
    self.is_updating_value = false
  end

  --Set value from value field  (maybe not real value...)
  function Parameter:vf_set_value(display_value)
    if self.is_updating_value then 
      return
    end
    self.is_updating_value = true
    local value = self:display_value_to_actual_value(display_value)
    print(("#VF set value# param = %s display = %s actual = %s"):format(self.id,display_value,value))
    self:set_changed()
    self.value = value
    self.patch_document_variable.value = value
    local vb = self.synth_definition.view_builder
    local ui_element = vb.views[self.id]
    if ui_element ~= nil then
      ui_element.value = display_value
    end
    self:send_midi()
    self.is_updating_value = false
  end

  function Parameter:actual_value_to_display_value(value)
    value = value - self.min_value
    value = value * self.display_value_factor + self.display_min_value
    return math.floor(value + 0.5)
  end
  
  function Parameter:display_value_to_actual_value(value)
    value = value - self.display_min_value
    value = value * (1/self.display_value_factor) + self.min_value
    return math.floor(value + 0.5)
  end
  
  --== Send sysex for Parameter ==--    
  function Parameter:send_midi()
    local value = self.patch_document_variable.value    

    if (self.items ~= nil) then --== This is a switch ==--
      if (self.item_values ~= nil) then
        value = math.floor(value)
        value = self.item_values[value]
      else
        value = value - 1 --== Switch ui index 1, 2, 3 = sysex values 0, 1, 2 ==--
      end
    else --== This is a slider, just pass value on ==--
      value = math.floor(value + 0.5)
    end
    
    self.value = value

    if self.value_callback ~= nil then
      value = self:value_callback(self)
    end

    if (self.type == "sysex") then
      assert(self.sysex_message_template, "sysex_message_template not specified")
      self.synth_definition.midi:send_sysex(self.sysex_message_template, self.number, value)
    elseif self.type == "cc" then
      if self.synth_definition.id == "korg_poly800_hawk800" then --Sigh...
        self.synth_definition.midi:send_cc(84, self.number)
        self.synth_definition.midi:send_cc(85, value)              
      else
        self.synth_definition.midi:send_cc(self.number, value)
      end
    elseif self.type == "nrpn" then
      self.synth_definition.midi:send_nrpn(self.number,value)
    elseif self.type == "pitchbend" then
      self.synth_definition.midi:send_pitchbend(value)
    end
  end

  --== Create a user interface for Parameter ==--
  function Parameter:create_ui()
    local vb = self.synth_definition.view_builder
  
    local ui = vb:row {
      vb:text{
        text = self.name,
        width = 105
      }
    }

    if (self.items ~= nil) then
      if (#self.items > 10 or self.gui_type == "dropdown") then
        ui:add_child(
          vb:popup {
            id = self.id,
            width = 200,
            midi_mapping = self.midi_mapping_id,
            notifier = function(value)
              self:ui_set_value(value)
            end,          
            items = self.items
          }
        )      
      elseif (#self.items == 1 and self.item_values ~= nil) then
        --Super secret functionality for buttons
        ui:add_child(
          vb:button {
            id = self.id,
            width = 200,
            text = self.items[1],
            pressed = function()
              self.synth_definition.midi:send_cc(self.number, self.item_values[1])
            end,       
            midi_mapping = self.midi_mapping_id,
          }
        )      
      else
        ui:add_child(
          vb:switch {
            id = self.id,
            width = 200,
            midi_mapping = self.midi_mapping_id,
            notifier = function(value)
              self:ui_set_value(value)
            end,          
            items = self.items
          }
        )
      end
      ui:add_child(
        vb:space{
          width = 40
        }
      )
    else
      local min = self.min_value
      local max = self.max_value
      if self.display_min_value ~= nil and self.display_max_value ~= nil then
        min = self.display_min_value
        max = self.display_max_value
      end
      ui:add_child(
        vb:slider {
          id = self.id,
          width = 200,
          midi_mapping = self.midi_mapping_id,
          notifier = function(value)
            self:ui_set_value(value)
          end,          
          min = min,
          max = max
        }
      )
      ui:add_child(
        vb:valuefield{
          id = "valuefield_" .. self.id,
          width = 40,
          min = min,
          max = max,
          notifier = function(value)
            self:vf_set_value(value)
          end,
          tostring = function(value)
            return ("%.0f"):format(tostring(value))
          end,
          tonumber = function(value)
            local success, new_val = try_round(value)
            if (success) then
              value = new_val
              if (value < self.min_value) then value = self.min_value end
              if (value > self.max_value) then value = self.max_value end
              return value
            end
          end
        }
      )
      
    end

    return ui
  end
