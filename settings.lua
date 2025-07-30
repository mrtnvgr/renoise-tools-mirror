
--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

-- tools can have preferences, just like Renoise. To use them we first need 
-- to create a renoise.Document object which holds the options that we want to 
-- store/restore
-- create a document


my_options = renoise.Document.create("Xrns2XModPreferences") {
 app_path = "",
 convfreq = false,
 conv_type_value = 1,
 --ptmode = true,
 modvol = true,
 bass_email = "",
 bass_code = "",
 enable_note_validation = true,
 enable_instrument_settings = true,
 fmt_note_validation = VALIDATION_NONE,
 initial_tempo = DEFAULT_BPM,
 initial_ticks = DEFAULT_TICKS_ROW,
 portamento_accuracy_threshold = DEFAULT_PORTAMENTO_ACCURACY_THRESHOLD,
 pt_comp_mode = PROTRACKER_COMPATIBILITY_MODE_HARDWARE,
 pt_freq_mode = FREQ_PAL
}

renoise.tool().preferences = my_options

-- global
app_path = my_options.app_path.value
-- converter
convfreq = my_options.convfreq.value
conv_type_value = my_options.conv_type_value.value
--ptmode = my_options.ptmode.value
pt_comp_mode = my_options.pt_comp_mode.value
pt_freq_mode = my_options.pt_freq_mode.value
modvol = my_options.modvol.value
initial_tempo = my_options.initial_tempo.value
initial_ticks = my_options.initial_ticks.value
portamento_accuracy_threshold = my_options.portamento_accuracy_threshold.value
-- bass_net
bass_email = my_options.bass_email.value
bass_code = my_options.bass_code.value
-- helper
fmt_note_validation = my_options.fmt_note_validation.value
-- control panel
enable_note_validation = my_options.enable_note_validation.value
enable_instrument_settings = my_options.enable_instrument_settings.value
