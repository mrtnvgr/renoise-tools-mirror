--[[============================================================================

Renoise JX Programmer V1.10

Renoise reincarnation of the PG-800 programmer for Roland synthesizers JX-8P, JX-10 and MKS-70

============================================================================

Created 08 Jan 2011 by Cornbeast

Modified 14 Mar 2012 by Cornbeast V1.00
* First release, lots of stuff

Modified 21 Mar 2012 by Cornbeast V1.10
* Added support for JX10/MKS70
* Added switching between tone A and B
* Renamed "patch" to "tone"

============================================================================

Todo: 

* Send tone name to synth
* Add settings panel/window: set synth model, set auto send, midi in/out etc
* Don't send midi for all models (setting)
* Midi values does not affect parameter values until they are the same as initial value
* Bulk dump from synth (is it possible?)
* Checkbox to toggle if patch should be automatically sent when loaded
* Midi in, read JX patches from other JX/PG tools
* Online sharing of patches
* Deal with that focus is lost when modifying parameters while playing the PC keyboard

============================================================================

Anatomy of a Roland JX8P / JX10 / MKS70 sysex message

Tone = a single synthesizer voice.
Patch = one (JX8P) or two (JX10/MKS70) Tones plus some general settings, like portamento, Tone A/B balance etc.
Tone A/B is sometimes called U/L, Upper/Lower

+-------+--------------+------------------+------------+-------------+------------+-------------+-----------+------------+-------+
| Sysex | Manufacturer | Operation        | Midi basic | Model id /  | Level      | Group       | Param     | Value      | Sysex |
| start | id           | code             | channel    | Format type |            |             |           |            | end   |
+-------+--------------+------------------+------------+-------------+------------+-------------+-----------+------------+-------+
| F0    | 41 = Roland  | 36 = Individual  | 00 - 15    | 21 = JX8P   | 20 = Tone  | 01 = Tone A | 11 - 3A   | 00 - 7F    | F7    |
|       |              |      parameter   |            | 24 = JX10   |            | 02 = Tone B | (11 - 58) | (11 - 127) |       |
|       |              | 35 = All         | nn + 1 =   |      MKS70  |            |             |           |            |       |
|       |              |      parameters  | midi       |             |            |             | 0 - 9 =   |            |       |
|       |              | 37 = Bulk dump   | channel    |             |            |             | name      | in ASCII   |       |
|       |              |                  |            |             +------------+-------------+-----------+------------+       |
|       |              |                  |            |             | 30 = Patch |                 Todo....             |       | 
+-------+--------------+------------------+------------+-------------+------------+-------------+-----------+------------+-------+

============================================================================]]--

-- VARIABLES --------------------

midi_channel = 1
midi_out_device = nil
is_updating = false
is_loading = false

-- TONE DOC STUFF --------------------

current_tone = 1
current_tone_has_changed = false
current_tone_doc = nil
tone_doc_a = nil
tone_doc_b = nil
tone_a_filename = nil
tone_b_filename = nil
tone_a_has_changed = false
tone_b_has_changed = false

-- SYSEX PARAMETERS -------------------

sysex_dco1_range = 11
sysex_dco1_waveform = 12
sysex_dco1_tune = 13
sysex_dco1_lfo_mod_depth = 14
sysex_dco1_env_mod_depth = 15
sysex_dco2_range = 16
sysex_dco2_waveform = 17
sysex_dco2_crossmod = 18
sysex_dco2_tune = 19
sysex_dco2_fine_tune = 20
sysex_dco2_lfo_mod_depth = 21
sysex_dco2_env_mod_depth = 22
sysex_dco_dynamics = 26
sysex_dco_env_mode = 27
sysex_mixer_dco1 = 28
sysex_mixer_dco2 = 29
sysex_mixer_env_mod_depth = 30
sysex_mixer_dynamics = 31
sysex_mixer_env_mode = 32
sysex_hpf_cutoff_freq = 33
sysex_vcf_cutoff_freq = 34
sysex_vcf_resonance = 35
sysex_vcf_lfo_mod_depth = 36
sysex_vcf_env_mod_depth = 37
sysex_vcf_key_follow = 38
sysex_vcf_dynamics = 39
sysex_vcf_env_mode = 40
sysex_vca_level = 41
sysex_vca_dynamics = 42
sysex_vca_env_mode = 58
sysex_chorus = 43
sysex_lfo_waveform = 44
sysex_lfo_delay_time = 45
sysex_lfo_rate = 46
sysex_env1_attack_time = 47
sysex_env1_decay_time = 48
sysex_env1_sustain_level = 49
sysex_env1_release_time = 50
sysex_env1_key_follow = 51
sysex_env2_attack_time = 52
sysex_env2_decay_time = 53
sysex_env2_sustain_level = 54
sysex_env2_release_time = 55
sysex_env2_key_follow = 56

function create_tone_doc(name)
  local document = renoise.Document.create("JXProgrammer_tone") {
    name = name,
    dco1_range = 2,
    dco1_waveform = 4,
    dco1_lfo_mod_depth = 0,
    dco1_env_mod_depth = 0,
    dco1_tune = 64,
    dco2_range = 1,
    dco2_waveform = 4,
    dco2_lfo_mod_depth = 6,
    dco2_env_mod_depth = 0,
    dco2_tune = 64,
    dco2_fine_tune = 77,
    dco2_crossmod = 1,
    dco_dynamics = 1,
    dco_env_mode = 4,
    mixer_dco1 = 127,
    mixer_dco2 = 127,
    mixer_env_mod_depth = 0,
    mixer_dynamics = 1,
    mixer_env_mode = 4,
    hpf_cutoff_freq = 1,
    vcf_cutoff_freq = 49,
    vcf_resonance = 0,
    vcf_lfo_mod_depth = 0,
    vcf_env_mod_depth = 95,
    vcf_key_follow = 113,
    vcf_dynamics = 3,
    vcf_env_mode = 4,
    vca_level = 110,
    vca_dynamics = 1,
    vca_env_mode = 2,
    chorus = 2,
    lfo_waveform = 3,
    lfo_delay_time = 50,
    lfo_rate = 92,
    env1_attack_time = 0,
    env1_decay_time = 30,
    env1_sustain_level = 50,
    env1_release_time = 50,
    env1_key_follow = 1,
    env2_attack_time = 0,
    env2_decay_time = 34,
    env2_sustain_level = 24,
    env2_release_time = 50,
    env2_key_follow = 1,
  }
  return document
end

--Gaah, this is ugly but I found no other solution 
--to get the UI bindings to work
function copy_tone_doc(destination_doc, source_doc)
  destination_doc.name.value = source_doc.name.value
  destination_doc.dco1_range.value = source_doc.dco1_range.value
  destination_doc.dco1_waveform.value = source_doc.dco1_waveform.value
  destination_doc.dco1_lfo_mod_depth.value = source_doc.dco1_lfo_mod_depth.value
  destination_doc.dco1_env_mod_depth.value = source_doc.dco1_env_mod_depth.value
  destination_doc.dco1_tune.value = source_doc.dco1_tune.value
  destination_doc.dco2_range.value = source_doc.dco2_range.value
  destination_doc.dco2_waveform.value = source_doc.dco2_waveform.value
  destination_doc.dco2_lfo_mod_depth.value = source_doc.dco2_lfo_mod_depth.value
  destination_doc.dco2_env_mod_depth.value = source_doc.dco2_env_mod_depth.value
  destination_doc.dco2_tune.value = source_doc.dco2_tune.value
  destination_doc.dco2_fine_tune.value = source_doc.dco2_fine_tune.value
  destination_doc.dco2_crossmod.value = source_doc.dco2_crossmod.value
  destination_doc.dco_dynamics.value = source_doc.dco_dynamics.value
  destination_doc.dco_env_mode.value = source_doc.dco_env_mode.value
  destination_doc.mixer_dco1.value = source_doc.mixer_dco1.value
  destination_doc.mixer_dco2.value = source_doc.mixer_dco2.value
  destination_doc.mixer_env_mod_depth.value = source_doc.mixer_env_mod_depth.value
  destination_doc.mixer_dynamics.value = source_doc.mixer_dynamics.value
  destination_doc.mixer_env_mode.value = source_doc.mixer_env_mode.value
  destination_doc.hpf_cutoff_freq.value = source_doc.hpf_cutoff_freq.value
  destination_doc.vcf_cutoff_freq.value = source_doc.vcf_cutoff_freq.value
  destination_doc.vcf_resonance.value = source_doc.vcf_resonance.value
  destination_doc.vcf_lfo_mod_depth.value = source_doc.vcf_lfo_mod_depth.value
  destination_doc.vcf_env_mod_depth.value = source_doc.vcf_env_mod_depth.value
  destination_doc.vcf_key_follow.value = source_doc.vcf_key_follow.value
  destination_doc.vcf_dynamics.value = source_doc.vcf_dynamics.value
  destination_doc.vcf_env_mode.value = source_doc.vcf_env_mode.value
  destination_doc.vca_level.value = source_doc.vca_level.value
  destination_doc.vca_dynamics.value = source_doc.vca_dynamics.value
  destination_doc.vca_env_mode.value = source_doc.vca_env_mode.value
  destination_doc.chorus.value = source_doc.chorus.value
  destination_doc.lfo_waveform.value = source_doc.lfo_waveform.value
  destination_doc.lfo_delay_time.value = source_doc.lfo_delay_time.value
  destination_doc.lfo_rate.value = source_doc.lfo_rate.value
  destination_doc.env1_attack_time.value = source_doc.env1_attack_time.value
  destination_doc.env1_decay_time.value = source_doc.env1_decay_time.value
  destination_doc.env1_sustain_level.value = source_doc.env1_sustain_level.value
  destination_doc.env1_release_time.value = source_doc.env1_release_time.value
  destination_doc.env1_key_follow.value = source_doc.env1_key_follow.value
  destination_doc.env2_attack_time.value = source_doc.env2_attack_time.value
  destination_doc.env2_decay_time.value = source_doc.env2_decay_time.value
  destination_doc.env2_sustain_level.value = source_doc.env2_sustain_level.value
  destination_doc.env2_release_time.value = source_doc.env2_release_time.value
  destination_doc.env2_key_follow.value = source_doc.env2_key_follow.value
end

-- PREFERENCES --------------------

preferences = renoise.Document.create("JXProgrammer_Preferences") {
  midi_out_device_name = "",
  current_tone = 1
}
renoise.tool().preferences = preferences

-- MENU REGISTRATION --------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:JX Programmer",
  invoke = function()
    current_tone_doc = create_tone_doc("Init")
    tone_doc_a = create_tone_doc("Init")
    tone_doc_b = create_tone_doc("Init")
    add_notifiers()
    init()
    show_dialog() 
  end 
}

-- INIT --------------------

function init()
  preferences.current_tone.value = 1
  midi_out_device = nil
  print(preferences.midi_out_device_name.value)
  set_midi_out_device(preferences.midi_out_device_name.value)
  update_all_parameters()
end

-- MIDI --------------------

function set_midi_out_device(device_name)
  print(device_name)
  if (midi_out_device ~= nil and midi_out_device.is_open) then
    midi_out_device:close()
  end
  for k,v in pairs(renoise.Midi.available_output_devices()) do
    if (device_name == v) then
      midi_out_device = renoise.Midi.create_output_device(device_name)
      print(("MIDI out device changed to '%s'"):format(device_name))
      preferences.midi_out_device_name.value = device_name
      break
    end
  end
  if (midi_out_device == nil) then
    device_name = renoise.Midi.available_output_devices()[1]
    midi_out_device = renoise.Midi.create_output_device(device_name)
    print(("MIDI out device defaulted to '%s'"):format(device_name))
  end
end

-- SUPPORT  --------------------

function alert(message)
  local vb = renoise.ViewBuilder()
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local dialog_content_alert = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    vb:text {
      align = "center",
      width = 250,
      text = message
    }
  }
  renoise.app():show_custom_prompt("Alert", dialog_content_alert, {"OK"})
end

function confirm(message)
  local vb = renoise.ViewBuilder()
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local dialog_content_confirm = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    vb:text {
      align = "center",
      width = 250,
      text = message
    }
  }
  local pressed_button = renoise.app():show_custom_prompt("Confirm", dialog_content_confirm, {"Yes","No"})
  return pressed_button
end

-- LOAD / SAVE --------------------

function load_tone()
  local tone_doc = nil
  if (current_tone_has_changed) then
    local conf = confirm("The tone has been modified but not saved, are you sure you want to continue?")
    if not (conf == "Yes") then 
      return
    end
  end
  local filename = renoise.app():prompt_for_filename_to_read({"*.xml"}, "Load tone")
  if not (filename == "") then
    is_loading = true
    print("Loading")
    current_tone_doc:load_from(filename)
    print("Done loading")
    is_loading = false
    print("update all")
    update_all_parameters()
    current_tone_has_changed = false
    if (current_tone == 1) then
      tone_a_filename = filename
      copy_tone_doc(tone_doc_a, current_tone_doc)
    else
      tone_b_filename = filename
      copy_tone_doc(tone_doc_b, current_tone_doc)
    end
  end
end

function save_tone()
  if (current_tone_doc.name.value == "" or current_tone_doc.name.value == "Init") then
    alert("You need to enter a name for the tone")
    return
  end
  local filename = nil
  if (current_tone == 1) then
    filename = tone_a_filename
  else
    filename = tone_b_filename
  end
  if (filename == nil) then
    save_tone_as()
  else
    print(("Saving %s "):format(filename))
    current_tone_doc:save_as(filename)
    current_tone_has_changed = false
  end
end

function save_tone_as()
  if (current_tone_doc.name.value == "" or current_tone_doc.name.value == "Init") then
    alert("You need to enter a name for the tone")
    return
  end
  local filename = renoise.app():prompt_for_filename_to_write("xml", "Save tone")
  if not (filename == "") then
    print(("Saving as %s "):format(filename))
    current_tone_doc:save_as(filename)
    current_tone_has_changed = false
    if (current_tone == 1) then
      tone_a_filename = filename
    else
      tone_b_filename = filename
    end
  end
end

-- SWITCH TONE A/B --------------------

function switch_tone()
  current_tone = preferences.current_tone.value
  if (current_tone == 1) then
    copy_tone_doc(tone_doc_b, current_tone_doc)
    is_updating = true
    copy_tone_doc(current_tone_doc, tone_doc_a)
    is_updating = false
    tone_b_has_changed = current_tone_has_changed 
    current_tone_has_changed = tone_a_has_changed
  else
    copy_tone_doc(tone_doc_a, current_tone_doc)
    is_updating = true
    copy_tone_doc(current_tone_doc, tone_doc_b)
    is_updating = false
    tone_a_has_changed = current_tone_has_changed
    current_tone_has_changed = tone_b_has_changed
  end
end

-- SYSEX --------------------

function update_parameter_dco1_range()
  send_sysex_index(sysex_dco1_range, current_tone_doc.dco1_range.value)
end

function update_parameter_dco1_waveform()
  send_sysex_index(sysex_dco1_waveform, current_tone_doc.dco1_waveform.value)
end

function update_parameter_dco1_lfo_mod_depth()
  send_sysex(sysex_dco1_lfo_mod_depth,current_tone_doc.dco1_lfo_mod_depth.value)
end

function update_parameter_dco1_env_mod_depth()
  send_sysex(sysex_dco1_env_mod_depth,current_tone_doc.dco1_env_mod_depth.value)
end

function update_parameter_dco1_tune()
  send_sysex(sysex_dco1_tune,current_tone_doc.dco1_tune.value)
end

-- DCO 2

function update_parameter_dco2_range()
  send_sysex_index(sysex_dco2_range, current_tone_doc.dco2_range.value)
end

function update_parameter_dco2_waveform()
  send_sysex_index(sysex_dco2_waveform, current_tone_doc.dco2_waveform.value)
end

function update_parameter_dco2_lfo_mod_depth()
  send_sysex(sysex_dco2_lfo_mod_depth,current_tone_doc.dco2_lfo_mod_depth.value)
end

function update_parameter_dco2_env_mod_depth()
  send_sysex(sysex_dco2_env_mod_depth,current_tone_doc.dco2_env_mod_depth.value)
end

function update_parameter_dco2_tune()
  send_sysex(sysex_dco2_tune,current_tone_doc.dco2_tune.value)
end

function update_parameter_dco2_fine_tune()
  send_sysex(sysex_dco2_fine_tune,current_tone_doc.dco2_fine_tune.value)
end

function update_parameter_dco2_crossmod()
  send_sysex_index(sysex_dco2_crossmod,current_tone_doc.dco2_crossmod.value)
end

-- DCO

function update_parameter_dco_dynamics()
  send_sysex_index(sysex_dco_dynamics,current_tone_doc.dco_dynamics.value)
end

function update_parameter_dco_env_mode()
  send_sysex_index(sysex_dco_env_mode,current_tone_doc.dco_env_mode.value)
end

-- MIXER

function update_parameter_mixer_dco1()
  send_sysex(sysex_mixer_dco1,current_tone_doc.mixer_dco1.value)
end

function update_parameter_mixer_dco2()
  send_sysex(sysex_mixer_dco2,current_tone_doc.mixer_dco2.value)
end

function update_parameter_mixer_env_mod_depth()
  send_sysex(sysex_mixer_env_mod_depth,current_tone_doc.mixer_env_mod_depth.value)
end

function update_parameter_mixer_dynamics()
  send_sysex_index(sysex_mixer_dynamics,current_tone_doc.mixer_dynamics.value)
end

function update_parameter_mixer_env_mode()
  send_sysex_index(sysex_mixer_env_mode,current_tone_doc.mixer_env_mode.value)
end

-- VCF

function update_parameter_hpf_cutoff_freq()
  send_sysex_index(sysex_hpf_cutoff_freq,current_tone_doc.hpf_cutoff_freq.value)
end

function update_parameter_vcf_cutoff_freq()
  send_sysex(sysex_vcf_cutoff_freq,current_tone_doc.vcf_cutoff_freq.value)
end

function update_parameter_vcf_resonance()
  send_sysex(sysex_vcf_resonance,current_tone_doc.vcf_resonance.value)
end

function update_parameter_vcf_lfo_mod_depth()
  send_sysex(sysex_vcf_lfo_mod_depth,current_tone_doc.vcf_lfo_mod_depth.value)
end

function update_parameter_vcf_env_mod_depth()
  send_sysex(sysex_vcf_env_mod_depth,current_tone_doc.vcf_env_mod_depth.value)
end

function update_parameter_vcf_key_follow()
  send_sysex(sysex_vcf_key_follow,current_tone_doc.vcf_key_follow.value)
end

function update_parameter_vcf_dynamics()
  send_sysex_index(sysex_vcf_dynamics,current_tone_doc.vcf_dynamics.value)
end

function update_parameter_vcf_env_mode()
  send_sysex_index(sysex_vcf_env_mode,current_tone_doc.vcf_env_mode.value)
end

-- VCA

function update_parameter_vca_level()
  send_sysex(sysex_vca_level,current_tone_doc.vca_level.value)
end

function update_parameter_vca_dynamics()
  send_sysex_index(sysex_vca_dynamics,current_tone_doc.vca_dynamics.value)
end

function update_parameter_vca_env_mode()
  send_sysex_index2(sysex_vca_env_mode,current_tone_doc.vca_env_mode.value)
end

-- Chorus

function update_parameter_chorus()
  send_sysex_index(sysex_chorus,current_tone_doc.chorus.value)
end

-- LFO

function update_parameter_lfo_waveform()
  send_sysex_index(sysex_lfo_waveform,current_tone_doc.lfo_waveform.value)
end

function update_parameter_lfo_delay_time()
  send_sysex(sysex_lfo_delay_time,current_tone_doc.lfo_delay_time.value)
end

function update_parameter_lfo_rate()
  send_sysex(sysex_lfo_rate,current_tone_doc.lfo_rate.value)
end

-- ENV1

function update_parameter_env1_attack_time()
  send_sysex(sysex_env1_attack_time,current_tone_doc.env1_attack_time.value)
end

function update_parameter_env1_decay_time()
  send_sysex(sysex_env1_decay_time,current_tone_doc.env1_decay_time.value)
end

function update_parameter_env1_sustain_level()
  send_sysex(sysex_env1_sustain_level,current_tone_doc.env1_sustain_level.value)
end

function update_parameter_env1_release_time()
  send_sysex(sysex_env1_release_time,current_tone_doc.env1_release_time.value)
end

function update_parameter_env1_key_follow()
  send_sysex_index(sysex_env1_key_follow,current_tone_doc.env1_key_follow.value)
end

-- ENV2

function update_parameter_env2_attack_time()
  send_sysex(sysex_env2_attack_time,current_tone_doc.env2_attack_time.value)
end

function update_parameter_env2_decay_time()
  send_sysex(sysex_env2_decay_time,current_tone_doc.env2_decay_time.value)
end

function update_parameter_env2_sustain_level()
  send_sysex(sysex_env2_sustain_level,current_tone_doc.env2_sustain_level.value)
end

function update_parameter_env2_release_time()
  send_sysex(sysex_env2_release_time,current_tone_doc.env2_release_time.value)
end

function update_parameter_env2_key_follow()
  send_sysex_index(sysex_env2_key_follow,current_tone_doc.env2_key_follow.value)
end

function name_changed()
  if not (is_updating) then
    current_tone_has_changed = true
  end
end

-- TONE DOCUMENT NOTIFIERS --------------------

function add_notifiers()
  if not (preferences.current_tone:has_notifier(switch_tone)) then
    preferences.current_tone:add_notifier(switch_tone)
  end
  current_tone_doc.name:add_notifier(name_changed)
  current_tone_doc.dco1_range:add_notifier(update_parameter_dco1_range)
  current_tone_doc.dco1_waveform:add_notifier(update_parameter_dco1_waveform)
  current_tone_doc.dco1_lfo_mod_depth:add_notifier(update_parameter_dco1_lfo_mod_depth)
  current_tone_doc.dco1_env_mod_depth:add_notifier(update_parameter_dco1_env_mod_depth)
  current_tone_doc.dco1_tune:add_notifier(update_parameter_dco1_tune)
  current_tone_doc.dco2_range:add_notifier(update_parameter_dco2_range)
  current_tone_doc.dco2_waveform:add_notifier(update_parameter_dco2_waveform)
  current_tone_doc.dco2_lfo_mod_depth:add_notifier(update_parameter_dco2_lfo_mod_depth)
  current_tone_doc.dco2_env_mod_depth:add_notifier(update_parameter_dco2_env_mod_depth)
  current_tone_doc.dco2_tune:add_notifier(update_parameter_dco2_tune)
  current_tone_doc.dco2_fine_tune:add_notifier(update_parameter_dco2_fine_tune)
  current_tone_doc.dco2_crossmod:add_notifier(update_parameter_dco2_crossmod)
  current_tone_doc.dco_dynamics:add_notifier(update_parameter_dco_dynamics)
  current_tone_doc.dco_env_mode:add_notifier(update_parameter_dco_env_mode)
  current_tone_doc.mixer_dco1:add_notifier(update_parameter_mixer_dco1)
  current_tone_doc.mixer_dco2:add_notifier(update_parameter_mixer_dco2)
  current_tone_doc.mixer_env_mod_depth:add_notifier(update_parameter_mixer_env_mod_depth)
  current_tone_doc.mixer_dynamics:add_notifier(update_parameter_mixer_dynamics)
  current_tone_doc.mixer_env_mode:add_notifier(update_parameter_mixer_env_mode)
  current_tone_doc.hpf_cutoff_freq:add_notifier(update_parameter_hpf_cutoff_freq)
  current_tone_doc.vcf_cutoff_freq:add_notifier(update_parameter_vcf_cutoff_freq)
  current_tone_doc.vcf_resonance:add_notifier(update_parameter_vcf_resonance)
  current_tone_doc.vcf_lfo_mod_depth:add_notifier(update_parameter_vcf_lfo_mod_depth)
  current_tone_doc.vcf_env_mod_depth:add_notifier(update_parameter_vcf_env_mod_depth)
  current_tone_doc.vcf_key_follow:add_notifier(update_parameter_vcf_key_follow)
  current_tone_doc.vcf_dynamics:add_notifier(update_parameter_vcf_dynamics)
  current_tone_doc.vcf_env_mode:add_notifier(update_parameter_vcf_env_mode)
  current_tone_doc.vca_level:add_notifier(update_parameter_vca_level)
  current_tone_doc.vca_dynamics:add_notifier(update_parameter_vca_dynamics)
  current_tone_doc.vca_env_mode:add_notifier(update_parameter_vca_env_mode)
  current_tone_doc.chorus:add_notifier(update_parameter_chorus)
  current_tone_doc.lfo_waveform:add_notifier(update_parameter_lfo_waveform)
  current_tone_doc.lfo_delay_time:add_notifier(update_parameter_lfo_delay_time)
  current_tone_doc.lfo_rate:add_notifier(update_parameter_lfo_rate)
  current_tone_doc.env1_attack_time:add_notifier(update_parameter_env1_attack_time)
  current_tone_doc.env1_decay_time:add_notifier(update_parameter_env1_decay_time)
  current_tone_doc.env1_sustain_level:add_notifier(update_parameter_env1_sustain_level)
  current_tone_doc.env1_release_time:add_notifier(update_parameter_env1_release_time)
  current_tone_doc.env1_key_follow:add_notifier(update_parameter_env1_key_follow)
  current_tone_doc.env2_attack_time:add_notifier(update_parameter_env2_attack_time)
  current_tone_doc.env2_decay_time:add_notifier(update_parameter_env2_decay_time)
  current_tone_doc.env2_sustain_level:add_notifier(update_parameter_env2_sustain_level)
  current_tone_doc.env2_release_time:add_notifier(update_parameter_env2_release_time)
  current_tone_doc.env2_key_follow:add_notifier(update_parameter_env2_key_follow)
end

-- UPDATE ALL PARAMS VIA SYSEX --------------------

function update_all_parameters()
  is_updating = true
  print("Updating")
  update_parameter_dco1_range()
  update_parameter_dco1_waveform()
  update_parameter_dco1_lfo_mod_depth()
  update_parameter_dco1_env_mod_depth()
  update_parameter_dco1_tune()
  update_parameter_dco2_range()
  update_parameter_dco2_waveform()
  update_parameter_dco2_lfo_mod_depth()
  update_parameter_dco2_env_mod_depth()
  update_parameter_dco2_tune()
  update_parameter_dco2_fine_tune()
  update_parameter_dco2_crossmod()
  update_parameter_dco_dynamics()
  update_parameter_dco_env_mode()
  update_parameter_mixer_dco1()
  update_parameter_mixer_dco2()
  update_parameter_mixer_env_mod_depth()
  update_parameter_mixer_dynamics()
  update_parameter_mixer_env_mode()
  update_parameter_hpf_cutoff_freq()
  update_parameter_vcf_cutoff_freq()
  update_parameter_vcf_resonance()
  update_parameter_vcf_lfo_mod_depth()
  update_parameter_vcf_env_mod_depth()
  update_parameter_vcf_key_follow()
  update_parameter_vcf_dynamics()
  update_parameter_vcf_env_mode()
  update_parameter_vca_level()
  update_parameter_vca_dynamics()
  update_parameter_vca_env_mode()
  update_parameter_chorus()
  update_parameter_lfo_waveform()
  update_parameter_lfo_delay_time()
  update_parameter_lfo_rate()
  update_parameter_env1_attack_time()
  update_parameter_env1_decay_time()
  update_parameter_env1_sustain_level()
  update_parameter_env1_release_time()
  update_parameter_env1_key_follow()
  update_parameter_env2_attack_time()
  update_parameter_env2_decay_time()
  update_parameter_env2_sustain_level()
  update_parameter_env2_release_time()
  update_parameter_env2_key_follow()
  is_updating = false
  print("Done updating")
end

-- SYSEX --------------------

-- Send the value as sysex to synth
function send_sysex(param, value)
  if not (is_loading) then
    if (value > 127) then value = 127 end
    if not (is_updating) then
      current_tone_has_changed = true
    end
    value = math.floor(value + 0.5)
    print(("Send sysex %s %s"):format(param,value))
    midi_out_device:send {0xF0, 0x41, 0x36, 0x00, 0x21, 0x20, 0x01, param, value, 0xF7} --JX8P
    if (current_tone == 1) then
      midi_out_device:send {0xF0, 0x41, 0x36, 0x00, 0x24, 0x20, 0x01, param, value, 0xF7} --JX10/MKS70 Tone A
    else
      midi_out_device:send {0xF0, 0x41, 0x36, 0x00, 0x24, 0x20, 0x02, param, value, 0xF7} --JX10/MKS70 Tone B
    end
  end
end

-- Send indexed value (ui switch) to synth
-- For switches with 4 buttons
function send_sysex_index(param, index)
  local value = nil
  if (index == 1) then 
    value = 1
  elseif (index == 2) then 
    value = 32
  elseif (index == 3) then 
    value = 64
  elseif (index == 4) then 
    value = 96
  end
  send_sysex(param, value)
end

-- Send indexed value (ui switch) to synth
-- For switches with 2 buttons
function send_sysex_index2(param, index)
  local value = nil
  if (index == 1) then 
    value = 1
  elseif (index == 2) then 
    value = 64
  end
  send_sysex(param, value)
end

-- MIDI MAPPINGS -------------------

-- TONE

-- Switch between tone A/B
renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:current_tone",
  invoke = function(message)
    local value = math.floor(message.int_value + 0.5) 
    if (value < 64) then
      preferences.current_tone.value = 1
    else
      preferences.current_tone.value = 2
    end
  end
}

-- DCO 2

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco1_range",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.dco1_range, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco1_waveform",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.dco1_waveform, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco1_lfo_mod_depth",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.dco1_lfo_mod_depth, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco1_env_mod_depth",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.dco1_env_mod_depth, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco1_tune",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.dco1_tune, message)
  end
}

-- DCO 2

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco2_range",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.dco2_range, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco2_waveform",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.dco2_waveform, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco2_lfo_mod_depth",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.dco2_lfo_mod_depth, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco2_env_mod_depth",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.dco2_env_mod_depth, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco2_tune",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.dco2_tune, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco2_fine_tune",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.dco2_fine_tune, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco2_crossmod",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.dco2_crossmod, message)
  end
}

-- DCO

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco_dynamics",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.dco_dynamics, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:dco_env_mode",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.dco_env_mode, message)
  end
}

-- MIXER

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:mixer_dco1",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.mixer_dco1, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:mixer_dco2",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.mixer_dco2, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:mixer_env_mod_depth",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.mixer_env_mod_depth, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:mixer_dynamics",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.mixer_dynamics, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:mixer_env_mode",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.mixer_env_mode, message)
  end
}

-- VCF

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:hpf_cutoff_freq",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.hpf_cutoff_freq, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:vcf_cutoff_freq",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.vcf_cutoff_freq, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:vcf_resonance",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.vcf_resonance, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:vcf_lfo_mod_depth",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.vcf_lfo_mod_depth, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:vcf_env_mod_depth",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.vcf_env_mod_depth, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:vcf_key_follow",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.vcf_key_follow, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:vcf_dynamics",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.vcf_dynamics, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:vcf_env_mode",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.vcf_env_mode, message)
  end
}

-- VCA

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:vca_level",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.vca_level, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:vca_dynamics",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.vca_dynamics, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:vca_env_mode",
  invoke = function(message)
    handle_midi_mapping_message_index2(current_tone_doc.vca_env_mode, message)
  end
}

-- CHORUS

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:chorus",
  invoke = function(message)
    handle_midi_mapping_message_index3(current_tone_doc.chorus, message)
  end
}

-- LFO

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:lfo_waveform",
  invoke = function(message)
    handle_midi_mapping_message_index3(current_tone_doc.lfo_waveform, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:lfo_delay_time",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.lfo_delay_time, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:lfo_rate",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.lfo_rate, message)
  end
}

-- ENV1

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:env1_attack_time",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.env1_attack_time, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:env1_decay_time",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.env1_decay_time, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:env1_sustain_level",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.env1_sustain_level, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:env1_release_time",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.env1_release_time, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:env1_key_follow",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.env1_key_follow, message)
  end
}

-- ENV2

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:env2_attack_time",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.env2_attack_time, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:env2_decay_time",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.env2_decay_time, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:env2_sustain_level",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.env2_sustain_level, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:env2_release_time",
  invoke = function(message)
    handle_midi_mapping_message(current_tone_doc.env2_release_time, message)
  end
}

renoise.tool():add_midi_mapping{
  name = "com.cornbeast.JXProgrammer:env2_key_follow",
  invoke = function(message)
    handle_midi_mapping_message_index(current_tone_doc.env2_key_follow, message)
  end
}

-- HANDLE MIDI MAPPINGS -------------------

--Changes document variable, so that its notifiers and 
--bindings are called to update ui and send sysex
function handle_midi_mapping_message(parameter, message)
  parameter.value = message.int_value
end

function handle_midi_mapping_message_index(parameter, message)
  parameter.value = math.floor(message.int_value / 32) + 1
end

function handle_midi_mapping_message_index2(parameter, message)
  local value = math.floor(message.int_value / 64) + 1
  if (value > 2) then value = 2 end
  parameter.value = value
end

function handle_midi_mapping_message_index3(parameter, message)
  local value = math.floor(message.int_value / 32) + 1
  if (value > 3) then value = 3 end
  parameter.value = value
end

-- MAIN DIALOG  --------------------

function show_dialog()

  local vb = renoise.ViewBuilder()
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local selected_midi_out_device = 1
  if not (midi_out_device == nil) then
    for k,v in pairs(renoise.Midi.available_output_devices()) do
      if (midi_out_device.name == v) then
        selected_midi_out_device = k
      end
    end
  end

  local content_tone = vb:row {
    vb:space{
      width=10
    },
    vb:column {
      vb:space{
        height=55
      },
      vb:row {
        vb:text {
          text = "Tone"
        },
        vb:space{
          width=10
        },
        vb:switch{
          id = "switch_tone",
          width = 90,
          items = {"A", "B"},
          midi_mapping = "com.cornbeast.JXProgrammer:current_tone",
          bind = preferences.current_tone
        }
      }
    },
    vb:space{
      width=520
    },
    vb:column{
      vb:space{
        height=35
      },    
      vb:text {
        text = "MIDI out",
      },
      vb:space{
        width=10
      },
      vb:popup {
        id = "popup_midi_out",
        width = 180,
        value = selected_midi_out_device,
        items = renoise.Midi.available_output_devices(),
        notifier = function(new_index)
          set_midi_out_device(vb.views.popup_midi_out.items[new_index])
        end
      }
    },
    vb:space{
      width=25
    },
    vb:column{
      vb:bitmap{
        bitmap = "jxprogrammer_logo.png",
        mode = "transparent",
        notifier = function()
          renoise.app():open_url("http://blog.cornbeast.com")
        end
      },
      vb:space{
        height=10
      }
    }
  }
  
  local content_tone_properties = vb:row {
    vb:column {
      vb:space{
        height=10
      },
      vb:row {
        vb:space{
          width=10
        },
        vb:text {
          text = "Tone name"
        },
        vb:space{
          width=10
        },
        vb:textfield {
          id = "textfield_tone_name",
          width = 180,
          bind = current_tone_doc.name
        },
        vb:space{
          width=6
        },
        vb:button {
          text = "Save",
          id = "button_save_tone",
          width = 70,
          notifier = save_tone
        },
        vb:space{
          width=6
        },
        vb:button {
          text = "Save as...",
          id = "button_save_tone_as",
          width = 70,
          notifier = save_tone_as
        },
        vb:space{
          width=6
        },
        vb:button {
          text = "Load...",
          id = "button_load_tone",
          width = 70,
          notifier = load_tone
        },
        vb:space{
          width=25
        },
        vb:button {
          text = "Resend",
          id = "button_resend",
          width = 80,
          notifier = update_all_parameters
        }
      },
      vb:space{
        height=20
      }      
    }
  }
  
  local content_dco1 = vb:column{
    margin = 10,
    spacing = 5,
    style = "group",
    vb:text {
      text = "DCO 1",
      align = "center",
      font = "bold"
    },
    vb:row{
      vb:text {
        text = "Range",
        width = 70
      },
      vb:switch {
        id = "switch_dco1_range",
        width = 180,
        items = {" 16 '", " 8 '", " 4' "," 2' "},
        midi_mapping = "com.cornbeast.JXProgrammer:dco1_range",      
        bind = current_tone_doc.dco1_range,
      },
    },
    vb:row{
      vb:text {
        text = "Waveform",
        width = 70
      },
      vb:switch {
        id = "switch_dco1_waveform",
        width = 180,
        items = {"Noise", "Square", "Pulse", "Saw"},
        midi_mapping = "com.cornbeast.JXProgrammer:dco1_waveform",
        bind = current_tone_doc.dco1_waveform
      }
    },
    vb:row{
      vb:text {
        text = "LFO mod",
        width = 70
      },
      vb:slider {
        id = "slider_dco1_lfo_mod_depth",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:dco1_lfo_mod_depth",
        bind = current_tone_doc.dco1_lfo_mod_depth
      },
      vb:valuefield{
        width = 40,     
        bind = current_tone_doc.dco1_lfo_mod_depth,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end
      }
    },
    vb:row{
      vb:text {
        text = "Env mod",
        width = 70
      },
      vb:slider {
        id = "slider_dco1_env_mod_depth",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:dco1_env_mod_depth",
        bind = current_tone_doc.dco1_env_mod_depth
      },
      vb:valuefield{
        width = 40,
        bind = current_tone_doc.dco1_env_mod_depth,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end
      }
    },
    vb:row{
      vb:text {
        text = "Tune",
        width = 70
      },
      vb:slider {
        id = "slider_dco1_tune",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:dco1_tune",
        bind = current_tone_doc.dco1_tune,
      },
      vb:valuefield{
        width = 40,
        bind = current_tone_doc.dco1_tune,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end
      }
    }
  }

  local content_dco2 = vb:column{
    margin = 10,
    spacing = 5,
    style = "group",
    vb:text {
      text = "DCO 2",
      align = "center",
      font = "bold"
    },    
    vb:row{
      vb:text {
        text = "Range",
        width = 70
      },
      vb:switch {
        id = "switch_dco2_range",
        width = 180,
        items = {" 16 '", " 8 '", " 4' "," 2' "},
        midi_mapping = "com.cornbeast.JXProgrammer:dco2_range",      
        bind = current_tone_doc.dco2_range
      },
    },
    vb:row{
      vb:text {
        text = "Waveform",
        width = 70
      },
      vb:switch {
        id = "switch_dco2_waveform",
        width = 180,
        items = {"Noise", "Square", "Pulse", "Saw"},
        midi_mapping = "com.cornbeast.JXProgrammer:dco2_waveform",
        bind = current_tone_doc.dco2_waveform
      }
    },
    vb:row{
      vb:text {
        text = "LFO mod",
        width = 70
      },
      vb:slider {
        id = "slider_dco2_lfo_mod_depth",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:dco2_lfo_mod_depth",
        bind = current_tone_doc.dco2_lfo_mod_depth
      },
      vb:valuefield{
        width = 40,
        bind = current_tone_doc.dco2_lfo_mod_depth,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Env mod",
        width = 70
      },
      vb:slider {
        id = "slider_dco2_env_mod_depth",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:dco2_env_mod_depth",
        bind = current_tone_doc.dco2_env_mod_depth
      },
      vb:valuefield{
        width = 40,
        bind = current_tone_doc.dco2_env_mod_depth,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Tune",
        width = 70
      },
      vb:slider {
        id = "slider_dco2_tune",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:dco2_tune",
        bind = current_tone_doc.dco2_tune
      },
      vb:valuefield{
        width = 40,
        bind = current_tone_doc.dco2_tune,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Fine tune",
        width = 70
      },
      vb:slider {
        id = "slider_dco2_fine_tune",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:dco2_fine_tune",
        bind = current_tone_doc.dco2_fine_tune
      },
      vb:valuefield{
        width = 40,
        bind = current_tone_doc.dco2_fine_tune,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Crossmod",
        width = 70
      },
      vb:switch {
        id = "switch_dco2_crossmod",
        width = 180,
        items = {"OFF", "SNC 1", "SNC 2", "XMOD"},
        midi_mapping = "com.cornbeast.JXProgrammer:dco2_crossmod",
        bind = current_tone_doc.dco2_crossmod
      }
    }
  }

  local content_dco = vb:column{
    --margin = 10,
    spacing = 5,
    vb:text {
      text = "Env mod",
      align = "center",
      font = "bold"
    },    
    vb:row{
      vb:text {
        text = "Dynamics",
        width = 70
      },
      vb:switch {
        id = "switch_dco_dynamics",
        width = 180,
        items = {"OFF", "1", "2", "3"},
        midi_mapping = "com.cornbeast.JXProgrammer:dco_dynamics",
        bind = current_tone_doc.dco_dynamics
      }
    },
    vb:row{
      vb:text {
        text = "Env mode",
        width = 70
      },
      vb:switch {
        id = "switch_dco_env_mode",
        width = 180,
        items = {"2 (inv)", "Env 2", "1 (inv)","Env 1"},
        midi_mapping = "com.cornbeast.JXProgrammer:dco_env_mode",      
        bind = current_tone_doc.dco_env_mode
      },
      vb:space{
        width = 60
      }
    }
  }

  local content_mixer = vb:column{
    margin = 10,
    spacing = 5,
    style = "group",
    vb:text {
      text = "Mixer",
      align = "center",
      font = "bold"
    },    
    vb:row{
      vb:text {
        text = "DCO-1",
        width = 70
      },
      vb:slider {
        id = "slider_mixer_dco1",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:mixer_dco1",
        bind = current_tone_doc.mixer_dco1
      },
      vb:valuefield{
        bind = current_tone_doc.mixer_dco1,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "DCO-2",
        width = 70
      },
      vb:slider {
        id = "slider_mixer_dco2",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:mixer_dco2",
        bind = current_tone_doc.mixer_dco2
      },
      vb:valuefield{
        bind = current_tone_doc.mixer_dco2,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Env mod",
        width = 70
      },
      vb:slider {
        id = "slider_mixer_env_mod_depth",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:mixer_env_mod_depth",
        bind = current_tone_doc.mixer_env_mod_depth
      },
      vb:valuefield{
        bind = current_tone_doc.mixer_env_mod_depth,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Dynamics",
        width = 70
      },
      vb:switch {
        id = "switch_mixer_dynamics",
        width = 180,
        items = {"OFF", "1", "2", "3"},
        midi_mapping = "com.cornbeast.JXProgrammer:dco_mixer_dynamics",      
        bind = current_tone_doc.mixer_dynamics
      }
    },
    vb:row{
      vb:text {
        text = "Mode",
        width = 70
      },
      vb:switch {
        id = "switch_mixer_env_mode",
        width = 180,
        items = {"2 (inv)", "Env 2", "1 (inv)"," Env 1"},
        midi_mapping = "com.cornbeast.JXProgrammer:mixer_env_mode",      
        bind = current_tone_doc.mixer_env_mode
      }
    } 
  }

  local content_vcf = vb:column{
    margin = 10,
    spacing = 5,
    style = "group",
    vb:text {
      text = "VCF",
      align = "center",
      font = "bold"
    },
    vb:row{
      vb:text {
        text = "HPF",
        width = 70
      },
      vb:switch {
        id = "switch_hpf_cutoff_freq",
        width = 180,
        items = {"0", "1", "2", "3"},
        midi_mapping = "com.cornbeast.JXProgrammer:hpf_cutoff_freq",      
        bind = current_tone_doc.hpf_cutoff_freq
      }
    }, 
    vb:row{
      vb:text {
        text = "Cutoff",
        width = 70
      },
      vb:slider {
        id = "slider_vcf_cutoff_freq",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:vcf_cutoff_freq",
        bind = current_tone_doc.vcf_cutoff_freq
      },
      vb:valuefield{
        bind = current_tone_doc.vcf_cutoff_freq,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },    
    vb:row{
      vb:text {
        text = "Resonance",
        width = 70
      },
      vb:slider {
        id = "slider_vcf_resonance",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:vcf_resonance",
        bind = current_tone_doc.vcf_resonance
      },
      vb:valuefield{
        bind = current_tone_doc.vcf_resonance,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },    
    vb:row{
      vb:text {
        text = "LFO mod",
        width = 70
      },
      vb:slider {
        id = "slider_vcf_lfo_mod_depth",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:vcf_lfo_mod_depth",
        bind = current_tone_doc.vcf_lfo_mod_depth
      },
      vb:valuefield{
        bind = current_tone_doc.vcf_lfo_mod_depth,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },    
    vb:row{
      vb:text {
        text = "Env mod",
        width = 70
      },
      vb:slider {
        id = "slider_vcf_env_mod_depth",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:vcf_env_mod_depth",
        bind = current_tone_doc.vcf_env_mod_depth
      },
      vb:valuefield{
        bind = current_tone_doc.vcf_env_mod_depth,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },    
    vb:row{
      vb:text {
        text = "Key follow",
        width = 70
      },
      vb:slider {
        id = "slider_vcf_key_follow",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:vcf_key_follow",
        bind = current_tone_doc.vcf_key_follow
      },
      vb:valuefield{
        bind = current_tone_doc.vcf_key_follow,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Dynamics",
        width = 70
      },
      vb:switch {
        id = "switch_vcf_dynamics",
        width = 180,
        items = {"OFF", "1", "2", "3"},
        midi_mapping = "com.cornbeast.JXProgrammer:vcf_dynamics",      
        bind = current_tone_doc.vcf_dynamics
      }
    },
    vb:row{
      vb:text {
        text = "Mode",
        width = 70
      },
      vb:switch {
        id = "switch_vcf_env_mode",
        width = 180,
        items = {"2 (inv)", "Env 2", "1 (inv)"," Env 1"},
        midi_mapping = "com.cornbeast.JXProgrammer:vcf_env_mode",      
        bind = current_tone_doc.vcf_env_mode
      }
    } 
  }    

  local content_vca = vb:column{
    margin = 10,
    spacing = 5,
    style = "group",
    vb:text {
      text = "VCA",
      align = "center",
      font = "bold"
    },
    vb:row{
      vb:text {
        text = "Level",
        width = 70
      },
      vb:slider {
        id = "slider_vca_level",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:vca_level",
        bind = current_tone_doc.vca_level
      },
      vb:valuefield{
        bind = current_tone_doc.vca_level,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Dynamics",
        width = 70
      },
      vb:switch {
        id = "switch_vca_dynamics",
        width = 180,
        items = {"OFF", "1", "2", "3"},
        midi_mapping = "com.cornbeast.JXProgrammer:vca_dynamics",      
        bind = current_tone_doc.vca_dynamics
      },
      vb:space{
        width = 60
      }
    },
    vb:row{
      vb:text {
        text = "Env mode",
        width = 70
      },
      vb:switch {
        id = "switch_vca_env_mode",
        width = 90,
        items = {"Gate", "Env 2"},
        midi_mapping = "com.cornbeast.JXProgrammer:vca_env_mode",      
        bind = current_tone_doc.vca_env_mode
      },
      vb:space{
        width = 150
      }
    },
    vb:space{
      height = 3
    }
    
  }

  local content_chorus = vb:column{
    margin = 10,
    spacing = 5,
    style = "group",
    vb:text {
      text = "Chorus",
      align = "center",
      font = "bold"
    },
    vb:row{
      vb:text {
        text = "Chorus",
        width = 70
      },
      vb:switch {
        id = "switch_chorus",
        width = 135,
        items = {"OFF", "1", "2"},
        midi_mapping = "com.cornbeast.JXProgrammer:chorus",      
        bind = current_tone_doc.chorus
      },
      vb:space{
        width = 105
      }
    },
    vb:space{
      height = 6
    }
  }

  local content_lfo = vb:column{
    margin = 10,
    spacing = 5,
    style = "group",
    vb:text {
      text = "LFO",
      align = "center",
      font = "bold"
    },
    vb:row{
      vb:text {
        text = "Waveform",
        width = 70
      },
      vb:switch {
        id = "switch_lfo_waveform",
        width = 135,
        items = {"RND", "Square", "Sine"},
        midi_mapping = "com.cornbeast.JXProgrammer:lfo_waveform",      
        bind = current_tone_doc.lfo_waveform
      },
      vb:space{
        width = 105
      }
    },
    vb:row{
      vb:text {
        text = "Delay time",
        width = 70
      },
      vb:slider {
        id = "slider_lfo_delay_time",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:lfo_delay_time",
        bind = current_tone_doc.lfo_delay_time
      },
      vb:valuefield{
        bind = current_tone_doc.lfo_delay_time,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Rate",
        width = 70
      },
      vb:slider {
        id = "slider_lfo_rate",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:lfo_rate",
        bind = current_tone_doc.lfo_rate
      },
      vb:valuefield{
        bind = current_tone_doc.lfo_rate,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    }
  }

  local content_env1 = vb:column{
    margin = 10,
    spacing = 5,
    style = "group",
    vb:text {
      text = "Envelope 1",
      align = "center",
      font = "bold"
    },
    vb:row{
      vb:text {
        text = "Attack time",
        width = 70
      },
      vb:slider {
        id = "slider_env1_attack_time",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:env1_attack_time",
        bind = current_tone_doc.env1_attack_time
      },
      vb:valuefield{
        bind = current_tone_doc.env1_attack_time,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Decay time",
        width = 70
      },
      vb:slider {
        id = "slider_env1_decay_time",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:env1_decay_time",
        bind = current_tone_doc.env1_decay_time
      },
      vb:valuefield{
        bind = current_tone_doc.env1_decay_time,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Sustain level",
        width = 70
      },
      vb:slider {
        id = "slider_env1_sustain_level",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:env1_sustain_level",
        bind = current_tone_doc.env1_sustain_level
      },
      vb:valuefield{
        bind = current_tone_doc.env1_sustain_level,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Release time",
        width = 70
      },
      vb:slider {
        id = "slider_env1_release_time",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:env1_release_time",
        bind = current_tone_doc.env1_release_time
      },
      vb:valuefield{
        bind = current_tone_doc.env1_release_time,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Key follow",
        width = 70
      },
      vb:switch {
        id = "switch_env1_key_follow",
        width = 180,
        items = {"OFF", "1", "2", "3"},
        midi_mapping = "com.cornbeast.JXProgrammer:env1_key_follow",      
        bind = current_tone_doc.env1_key_follow
      },
      vb:space{
        width = 60
      }
    }
  }
  
  local content_env2 = vb:column{
    margin = 10,
    spacing = 5,
    style = "group",
    vb:text {
      text = "Envelope 2",
      align = "center",
      font = "bold"
    },
    vb:row{
      vb:text {
        text = "Attack time",
        width = 70
      },
      vb:slider {
        id = "slider_env2_attack_time",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:env2_attack_time",
        bind = current_tone_doc.env2_attack_time
      },
      vb:valuefield{
        bind = current_tone_doc.env2_attack_time,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Decay time",
        width = 70
      },
      vb:slider {
        id = "slider_env2_decay_time",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:env2_decay_time",
        bind = current_tone_doc.env2_decay_time
      },
      vb:valuefield{
        bind = current_tone_doc.env2_decay_time,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Sustain level",
        width = 70
      },
      vb:slider {
        id = "slider_env2_sustain_level",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:env2_sustain_level",
        bind = current_tone_doc.env2_sustain_level
      },
      vb:valuefield{
        bind = current_tone_doc.env2_sustain_level,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Release time",
        width = 70
      },
      vb:slider {
        id = "slider_env2_release_time",
        min = 0,
        max = 127,
        width = 180,
        midi_mapping = "com.cornbeast.JXProgrammer:env2_release_time",
        bind = current_tone_doc.env2_release_time
      },
      vb:valuefield{
        bind = current_tone_doc.env2_release_time,
        tostring = function(value)
          return ("%.0f"):format(tostring(value))
        end,
        tonumber = function(value)
          return math.floor(value + 0.5)
        end        
      }
    },
    vb:row{
      vb:text {
        text = "Key follow",
        width = 70
      },
      vb:switch {
        id = "switch_env2_key_follow",
        width = 180,
        items = {"OFF", "1", "2", "3"},
        midi_mapping = "com.cornbeast.JXProgrammer:env2_key_follow",      
        bind = current_tone_doc.env2_key_follow
      },
      vb:space{
        width = 60
      }
    }
  }  

  local dialog_content = vb:vertical_aligner{
    margin = 10,
    vb:horizontal_aligner{
      content_tone
    },
    vb:column{
      margin = 10,
      style = "panel",
      vb:horizontal_aligner{
        spacing = 5,
        content_tone_properties
      },
      vb:horizontal_aligner{
        spacing = 5,
        vb:column{
          margin = 10,
          spacing = 5,
          style = "group",
          vb:text {
            text = "Oscillators",
            align = "center",
            font = "bold"
          },
          content_dco1,
          content_dco2,
          content_dco,
          vb:space{
            height = 26
          },
        },
        vb:vertical_aligner{
          spacing = 5,
          content_mixer,
          content_vcf,
          content_vca      
        },
        vb:vertical_aligner{
          spacing = 5,
          content_lfo,
          content_env1,
          content_env2,
          content_chorus,
        }    
      }
    }
  }
  renoise.app():show_custom_dialog("JX Programmer", dialog_content)
end

