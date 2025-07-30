--[[--------------------------------------------------------------------------------
MACIULXOCHITL                                                                      -
files.lua                                                                          -
Global values and IO operations                                                    -
]]----------------------------------------------------------------------------------

def = {
  --   First goes defaults / not saving /
  SAMPLE_MAX_AMPLITUDE = 1.0,
  SAMPLE_MIN_AMPLITUDE = -1.0,
  SAMPLE_MAX_PHASE = 1024,
  SAMPLE_FREQUENCY = 44100,
  SAMPLE_MAX_PERIOD=256,
  SAMPLE_MIN_PERIOD = 1,
  SAMPLE_BIT_DEPTH = 16,
  SAMPLE_CHANNELS = 1,
  SAMPLE_MIN_NOISE = 0.001,
  SAMPLE_MAX_NOISE = 1.0,
  SAMPLE_MIN_FILTER_FREQ = 20,
  SAMPLE_MAX_FILTER_FREQ = 20000,
  SAMPLE_MIN_FILTER_QUALITY = 1,
  SAMPLE_MAX_FILTER_QUALITY = 100,
  SAMPLE_MIN_FILTER_GAIN = -60,
  SAMPLE_MAX_FILTER_GAIN = 60,
  SAMPLE_MIN_FILTER_WET = 0,
  SAMPLE_MAX_FILTER_WET = 1.0,
  GAUSSIAN_V_MAX = 1.0,
  GAUSSIAN_V_MIN = 0.0,
  GAUSSIAN_N_MAX = 10.0,
  GAUSSIAN_N_MIN = 0.0,
  GAUSSIAN_S_MAX = 0.0,
  GAUSSIAN_S_MIN = -10.0,
  GAUSSIAN_RND = 4,
}

tmp = {
  -- now get saved values
  INSTRUMENT_NAME = "default",

  SAMPLE_NAME = "Sample",
  SAMPLE_FRAMES = 84,
  SAMPLE_POPUP = 1,
  SAMPLE_BUFFER_SELECTOR = 1,
  SAMPLE_FREQUENCY_1 = 1.0,
  SAMPLE_FREQUENCY_2 = 1.0,
  SAMPLE_FREQUENCY_3 = 1.0,
  SAMPLE_AMPLITUDE_1 = 0.5,
  SAMPLE_AMPLITUDE_2 = 0.5,
  SAMPLE_AMPLITUDE_3 = 0.5,
  SAMPLE_PHASE_1 = 0,
  SAMPLE_PHASE_2 = 0,
  SAMPLE_PHASE_3 = 0,
  SAMPLE_TYPE_1 = 1,
  SAMPLE_TYPE_2 = 1,
  SAMPLE_TYPE_3 = 1,
  SAMPLE_DETAIL_1 = 1,
  SAMPLE_DETAIL_2 = 1,
  SAMPLE_DETAIL_3 = 1,
  SAMPLE_BEAT_SYNC_ENABLED = false,
  SAMPLE_BEAT_SYNC_MODE = 1,
  SAMPLE_BEAT_SYNC_LINES = 16,
  SAMPLE_LOOP_MODE = 2,
  SAMPLE_LOOP_RELEASE = false,
  SAMPLE_LOOP_START = 1,
  SAMPLE_LOOP_END = 512,
  SAMPLE_PANNING = 0.5,
  SAMPLE_VOLUME = 1.0,
  SAMPLE_TRANSPOSE = 0.0,
  SAMPLE_FINE_TUNE = 0.0,
  SAMPLE_INTERPOLATION_MODE = 1,
  SAMPLE_OVERSAMPLE_ENABLED = false,
  SAMPLE_NEW_NOTE_ACTION = 1,
  SAMPLE_ONESHOT = false,
  SAMPLE_MUTE_GROUP = 0,
  SAMPLE_AUTOSEEK = false,
  SAMPLE_AUTOFADE = false,

  SAMPLE_NOISE_BOOL = false,
  SAMPLE_NOISE_TYPE = 1,
  SAMPLE_NOISE_AMOUNT = def.SAMPLE_MIN_NOISE,

  SAMPLE_FILTER_TOGGLE = false,
  SAMPLE_FILTER_TYPE = 1,
  SAMPLE_FILTER_FREQ = 200,
  SAMPLE_FILTER_QUALITY = 20,
  SAMPLE_FILTER_GAIN = 30,
  SAMPLE_FILTER_WET = 0.5,
  SAMPLE_FILTER_VOWEL = 1,
  
  GAUSSIAN_ON_OFF = false,
  GAUSSIAN_V1 = 0.1,
  GAUSSIAN_V2 = 0.2,
  GAUSSIAN_V3 = 0.3,
  GAUSSIAN_V4 = 0.4,
  GAUSSIAN_V5 = 0.5,

  GAUSSIAN_N1 = 1,
  GAUSSIAN_N2 = 2.2,
  GAUSSIAN_N3 = 3,
  GAUSSIAN_N4 = 4.2,
  GAUSSIAN_N5 = 4.8,

  GAUSSIAN_S1 = -1,
  GAUSSIAN_S2 = -2,
  GAUSSIAN_S3 = -3,
  GAUSSIAN_S4 = -4,
  GAUSSIAN_S5 = -5,

  FINISHER_POPUP = 1,
  FINISHER_AMOUNT = 0.5,

  OP1 = 1,
  OP2 = 1,

  OSC1_FREQUENCY_MOD = false,
  OSC1_AMPLITUDE_MOD = false,
  OSC1_PHASE_MOD = false,
  OSC1_DETAIL_MOD = false,

  OSC2_FREQUENCY_MOD = false,
  OSC2_AMPLITUDE_MOD = false,
  OSC2_PHASE_MOD = false,

  OSC3_FREQUENCY_MOD = false,
  OSC3_AMPLITUDE_MOD = false,
  OSC3_PHASE_MOD = false,

  MODULATION_FLOW = 1,
}


function deepcopy_table(item)
  local set = {}
  for k,v in pairs(item) do
    set[k] = v
  end
  return set
end

Settings_Default = deepcopy_table(tmp)
--Settings_Mono = deepcopy_table(tmp)
--Settings_Left = deepcopy_table(tmp)
--Settings_Right = deepcopy_table(tmp)


--[[-------------------------------------------------------------
Load config file as Lua 
]]---------------------------------------------------------------
function load_config(filename)
  
  -- load lua file and parse it
  local ftables,err = loadfile(filename)
  
  if err then
    renoise.app():show_error("ERROR:Can't load patch file" .. filename)
    return
  end
  
  local tables = ftables()
  
  for idx = 1,#tables do
    
    local tolinki = {}
    for i,v in pairs(tables[idx]) do
        
        if type(v) == "table" then
          tables[idx][i] = tables[v[1]]
        end
        
        if type(i) == "table" and tables[i[1]] then
          table.insert(tolinki, {i,tables[i[1]]})
        end
    
    end
    
    -- link indices
    for _,v in ipairs(tolinki) do
      tables[idx][v[2]],tables[idx][v[1]] = tables[idx][v[1]],nil
    end
  
  end
  return tables[1]
end


--[[-------------------------------------------------------------
Load patch file                                                 -
]]---------------------------------------------------------------
function load_patch_file(filename)

  if filename then
    tmp = load_config(filename)

    if not tmp then
      renoise.app():show_warning("This isn't Macuilxochitl config file !!!")
      tmp = deepcopy_table(Settings_Default)
    end
  else
    tmp = deepcopy_table(Settings_Default)
  end

  refresh_widgets(tmp)

end

function refresh_widgets(settings)

  tmp = deepcopy_table(settings)

  -- refresh gui widgets
  local vbv = vb.views
 
  vbv.freq1slider.value = tmp.SAMPLE_FREQUENCY_1
  vbv.freq1box.value = tmp.SAMPLE_FREQUENCY_1
  vbv.amp1slider.value = tmp.SAMPLE_AMPLITUDE_1
  vbv.amp1box.value = tmp.SAMPLE_AMPLITUDE_1
  vbv.phase1slider.value = tmp.SAMPLE_PHASE_1
  vbv.detail1slider.value = tmp.SAMPLE_DETAIL_1
  vbv.osc1type.value = tmp.SAMPLE_TYPE_1

  vbv.freq2slider.value = tmp.SAMPLE_FREQUENCY_2
  vbv.freq2box.value = tmp.SAMPLE_FREQUENCY_2
  vbv.amp2slider.value = tmp.SAMPLE_AMPLITUDE_2
  vbv.amp2box.value = tmp.SAMPLE_AMPLITUDE_2
  vbv.phase2slider.value = tmp.SAMPLE_PHASE_2
  vbv.detail2slider.value = tmp.SAMPLE_DETAIL_2
  vbv.osc2type.value = tmp.SAMPLE_TYPE_2
  
  vbv.freq3slider.value = tmp.SAMPLE_FREQUENCY_3
  vbv.freq3box.value = tmp.SAMPLE_FREQUENCY_3
  vbv.amp3slider.value = tmp.SAMPLE_AMPLITUDE_3
  vbv.amp3box.value = tmp.SAMPLE_AMPLITUDE_3
  vbv.phase3slider.value = tmp.SAMPLE_PHASE_3
  vbv.detail3slider.value = tmp.SAMPLE_DETAIL_3
  vbv.osc3type.value = tmp.SAMPLE_TYPE_3

  vbv.osc2freqmod.value = tmp.OSC2_FREQUENCY_MOD
  vbv.osc2ampmod.value = tmp.OSC2_AMPLITUDE_MOD
  vbv.osc2phasemod.value = tmp.OSC2_PHASE_MOD
  vbv.osc3freqmod.value = tmp.OSC3_FREQUENCY_MOD
  vbv.osc3ampmod.value = tmp.OSC3_AMPLITUDE_MOD
  vbv.osc3phasemod.value = tmp.OSC3_PHASE_MOD

  vbv.noise_popup.value = tmp.SAMPLE_NOISE_TYPE
  vbv.noise_toggle.value = tmp.SAMPLE_NOISE_BOOL
  vbv.noise_slider.value = tmp.SAMPLE_NOISE_AMOUNT
  vbv.noise_box.value = tmp.SAMPLE_NOISE_AMOUNT

  vbv.filter_toggle.value = tmp.SAMPLE_FILTER_TOGGLE
  vbv.filter_popup.value = tmp.SAMPLE_FILTER_TYPE
  vbv.filter_freq_box.value = tmp.SAMPLE_FILTER_FREQ
  vbv.filter_freq_slider.value = tmp.SAMPLE_FILTER_FREQ
  vbv.filter_quality_slider.value = tmp.SAMPLE_FILTER_QUALITY
  vbv.filter_quality_box.value = tmp.SAMPLE_FILTER_QUALITY
  vbv.filter_gain_slider.value = tmp.SAMPLE_FILTER_GAIN
  vbv.filter_gain_box.value = tmp.SAMPLE_FILTER_GAIN
  vbv.filter_wet_slider.value = tmp.SAMPLE_FILTER_WET
  vbv.filter_wet_box.value = tmp.SAMPLE_FILTER_WET
  vbv.filter_vowel.value = tmp.SAMPLE_FILTER_VOWEL

  if tmp.SAMPLE_FILTER_TYPE == 9 then   --- vowel filter
    vbv.filter_freq_row.visible=false
    vbv.filter_quality_row.visible=false
    vbv.filter_gain_row.visible=false
    vbv.filter_wet_row.visible=false
    vbv.filter_vowel_row.visible=true
  else
    vbv.filter_vowel_row.visible=false
  end

  vbv.framepopup.value = tmp.SAMPLE_POPUP
  --vbv.sample_channel_switch.value = tmp.SAMPLE_BUFFFER_SELECTOR

  vbv.framebox.value = tmp.SAMPLE_FRAMES

  vbv.op1.value = tmp.OP1
  vbv.op2.value = tmp.OP2

  if tmp.GAUSSIAN_ON_OFF then
    vbv.gaussian_on_off.value = true
  else
    vbv.gaussian_on_off.value = false
  end

  vbv.gauss_v1.value = tmp.GAUSSIAN_V1
  vbv.gauss_v2.value = tmp.GAUSSIAN_V2
  vbv.gauss_v3.value = tmp.GAUSSIAN_V3
  vbv.gauss_v4.value = tmp.GAUSSIAN_V4
  vbv.gauss_v5.value = tmp.GAUSSIAN_V5
  vbv.gauss_n1.value = tmp.GAUSSIAN_N1
  vbv.gauss_n2.value = tmp.GAUSSIAN_N2
  vbv.gauss_n3.value = tmp.GAUSSIAN_N3
  vbv.gauss_n4.value = tmp.GAUSSIAN_N4
  vbv.gauss_n5.value = tmp.GAUSSIAN_N5
  vbv.gauss_s1.value = tmp.GAUSSIAN_S1
  vbv.gauss_s2.value = tmp.GAUSSIAN_S2
  vbv.gauss_s3.value = tmp.GAUSSIAN_S3
  vbv.gauss_s4.value = tmp.GAUSSIAN_S4
  vbv.gauss_s5.value = tmp.GAUSSIAN_S5

  vbv.finisher_popup.value = tmp.FINISHER_POPUP
  vbv.finisher_slider.value = tmp.FINISHER_AMOUNT
  vbv.finisher_box.value = tmp.FINISHER_AMOUNT
 
end

--[[-------------------------------------------------------------
Save config file as Lua file
]]---------------------------------------------------------------
function save_config(filename, tab)
  local file, error = io.open(filename, "wb")
  
  if error then
    renoise.app():show_error("Can't save file " .. config_table)
    return
  end

  --table.sort(tab)
  
  file:write("return {\n-- Macuilxochitl Config file\n{\n")
  
  for key, value in pairs(tab) do
    if type(value) == "boolean" then
      if value then value="true" else value="false" end
    elseif type(value) == "string" then
      value = '"' .. tostring(value) .. '"'
      --value = string.format("%q", value)
    end
    file:write('\t["' .. key .. '"] = ' .. value .. ",\n")
  end
  
  file:write("},\n}")
  file:close()

end

--[[-------------------------------------------------------------
Save patch                                                      -
]]---------------------------------------------------------------
function save_patch_file(filename)

  local instrument = renoise.song().selected_instrument
  local sample = instrument:sample(1)
  tmp.INSTRUMENT_NAME = tostring(instrument.name)
  if sample.name then
    tmp.SAMPLE_NAME = tostring(sample.name)
  else
    tmp.SAMPLE_NAME = tostring(filename)
  end
  read_info_from_sample(sample, instrument)
  save_config(filename, tmp)

end
