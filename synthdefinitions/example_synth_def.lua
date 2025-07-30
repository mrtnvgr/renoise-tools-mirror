-- VCO 1 group
local group_vco1 = Group {
  name = "VCO 1",
  Parameter {
    id = "switch_example",
    name = "Switch example",
    number = 11,
    default_value = 2,
    items = {"16'","8'","4'","2'"}
  },
  Parameter {
    id = "button_example",
    name = "Button example",
    number = 10,
    items = {"Click"},
    item_values = {127}
  },
  Parameter {
    id = "pitchbend_example",
    name = "Pitchbend example",
    type = "pitchbend"
  },
  Parameter {
    id = "callback_function_example",
    name = "Callback example",
    number = 16,
    items = {"16'","8'","4'","2'"},
    item_values = {0,32,64,96},
    value_callback = function(parameter)
      local synth_definition = parameter.synth_definition
      local other_parameter = synth_definition.parameters["switch_example"]
      return parameter.value + other_parameter.value
    end
  },
  Parameter {
    id = "dropdown_example",
    name = "dropdown example",
    number = 11,
    default_value = 2,
    items = {"Long text","Here too","And here","Garrhh"},
    item_values = {0,32,64,96},
    gui_type = "dropdown"
  },
}

-- VCF group
local group_vcf = Group {
  name = "VCF",
  Parameter {
    id = "slider_example",
    name = "Slider example",
    number = 16,
    default_value = 80,
    randomize_min = 0,
    randomize_max = 20,
    display_min_value = -64,
    display_max_value = 63
  },
  Parameter {
    id = "cc_parameter_example",
    name = "CC example",
    type = "cc",
    number = 14,
    display_min_value = -50,
    display_max_value = 250
  },
  Parameter {
    id = "nrpn_parameter_example",
    name = "NRPN example",
    type = "nrpn",
    number = 227
  }
}

-- Synth definition
return SynthDefinition {
  id = "example_synth_def",
  name = "Example synth def",
  author = "Cornbeast [cornbeast@cornbeast.com]",
  beta = true,
  delay_between_midi_messages = 10,
  --omit_nrpn_lsb = true,
  content_height = 800,
  Section {
    sysex_message_template = {0xF0, 0x41, 0x36, "cc", 0x24, 0x20, 0x01, "nn", "vv", 0xF7},
    group_vco1,
    group_vcf
  }
}
