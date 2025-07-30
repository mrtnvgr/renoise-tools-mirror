-- Simple map function from one range to another range

local function map_from_to(val, fmin, fmax, tmin, tmax)
  return (val - fmin) / (fmax - fmin) * (tmax - tmin) + tmin
end


function toggle_midi_mapping()
  -------------------- OSC1 MIDI --------------------------------

  local rnt = renoise.tool()
  local vbv = vb.views

  if not rnt:has_midi_mapping("MX:OSC1_selector") then
    rnt:add_midi_mapping{
      name="MX:OSC1_selector",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, #WAVES)
        vbv.osc1type.value = val
        tmp.SAMPLE_TYPE_1 = val
        if MAIN_SAMPLE then
          read_info_from_sample(MAIN_SAMPLE, MAIN_INSTRUMENT)
        end
        redraw_sample()
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC1_selector")
  end

  if not rnt:has_midi_mapping("MX:OSC1_period") then
    rnt:add_midi_mapping{
      name="MX:OSC1_period",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, def.SAMPLE_MAX_PERIOD)
        vbv.freq1slider.value = val
        tmp.SAMPLE_FREQUENCY_1 = val
        if MAIN_SAMPLE then
          read_info_from_sample(MAIN_SAMPLE, MAIN_INSTRUMENT)
        end
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC1_period")
  end

  if not rnt:has_midi_mapping("MX:OSC1_amplitude") then
    rnt:add_midi_mapping{
      name="MX:OSC1_amplitude",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, -1, 1)
        vbv.amp1slider.value = val
        tmp.SAMPLE_AMPLITUDE_1 = val
        if MAIN_SAMPLE then
          read_info_from_sample(MAIN_SAMPLE, MAIN_INSTRUMENT)
        end
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC1_amplitude")
  end

  if not rnt:has_midi_mapping("MX:OSC1_phase") then
    rnt:add_midi_mapping{
      name="MX:OSC1_phase",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, -def.SAMPLE_MAX_PHASE, def.SAMPLE_MAX_PHASE)
        vbv.phase1slider.value = val
        tmp.SAMPLE_PHASE_1 = val
        if MAIN_SAMPLE then
          read_info_from_sample(MAIN_SAMPLE, MAIN_INSTRUMENT)
        end
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC1_phase")
  end

  if not rnt:has_midi_mapping("MX:OSC1_detail") then
    rnt:add_midi_mapping{
      name="MX:OSC1_detail",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, 128)
        vbv.detail1slider.value = val
        tmp.SAMPLE_DETAIL_1 = val
        if MAIN_SAMPLE then
          read_info_from_sample(MAIN_SAMPLE, MAIN_INSTRUMENT)
        end
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC1_detail")
  end

  ------------------------ OSC2 MIDI ----------------------------

  if not rnt:has_midi_mapping("MX:OSC2_selector") then
    rnt:add_midi_mapping{
      name="MX:OSC2_selector",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, #WAVES)
        vbv.osc2type.value = val
        tmp.SAMPLE_TYPE_2 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC2_selector")
  end

  if not rnt:has_midi_mapping("MX:OSC2_period") then
    rnt:add_midi_mapping{
      name="MX:OSC2_period",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, def.SAMPLE_MAX_PERIOD)
        vbv.freq2slider.value = val
        tmp.SAMPLE_FREQUENCY_2 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC2_period")
  end

  if not rnt:has_midi_mapping("MX:OSC2_amplitude") then
    rnt:add_midi_mapping{
      name="MX:OSC2_amplitude",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, -1, 1)
        vbv.amp2slider.value = val
        tmp.SAMPLE_AMPLITUDE_2 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC2_amplitude")
  end

  if not rnt:has_midi_mapping("MX:OSC2_phase") then
    rnt:add_midi_mapping{
      name="MX:OSC2_phase",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, -def.SAMPLE_MAX_PHASE, def.SAMPLE_MAX_PHASE)
        vbv.phase2slider.value = val
        tmp.SAMPLE_PHASE_2 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC2_phase")
  end

  if not rnt:has_midi_mapping("MX:OSC2_detail") then
    rnt:add_midi_mapping{
      name="MX:OSC2_detail",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, 128)
        vbv.detail2slider.value = val
        tmp.SAMPLE_DETAIL_2 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC2_detail")
  end

  ------------------------- OSC3 MIDI -----------------------------

  if not rnt:has_midi_mapping("MX:OSC3_selector") then
    rnt:add_midi_mapping{
      name="MX:OSC3_selector",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, #WAVES)
        vbv.osc3type.value = val
        tmp.SAMPLE_TYPE_3 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC3_selector")
  end

  if not rnt:has_midi_mapping("MX:OSC3_period") then
    rnt:add_midi_mapping{
      name="MX:OSC3_period",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, def.SAMPLE_MAX_PERIOD)
        vbv.freq3slider.value = val
        tmp.SAMPLE_FREQUENCY_3 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC3_period")
  end

  if not rnt:has_midi_mapping("MX:OSC3_amplitude") then
    rnt:add_midi_mapping{
      name="MX:OSC3_amplitude",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, -1, 1)
        vbv.amp3slider.value = val
        tmp.SAMPLE_AMPLITUDE_3 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC3_amplitude")
  end

  if not rnt:has_midi_mapping("MX:OSC3_phase") then
    rnt:add_midi_mapping{
      name="MX:OSC3_phase",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, -def.SAMPLE_MAX_PHASE, def.SAMPLE_MAX_PHASE)
        vbv.phase3slider.value = val
        tmp.SAMPLE_PHASE_3 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC3_phase")
  end

  if not rnt:has_midi_mapping("MX:OSC3_detail") then
    rnt:add_midi_mapping{
      name="MX:OSC3_detail",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, 128)
        vbv.detail3slider.value = val
        tmp.SAMPLE_DETAIL_3 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OSC3_detail")
  end

  ------------------------- NOISE AMOUNT --------------------------
  if not rnt:has_midi_mapping("MX:Noise_toggle") then
    rnt:add_midi_mapping{
      name="MX:Noise_toggle",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 0, 1)
        if val < 1 then
          tmp.SAMPLE_NOISE_BOOL = false
          vbv.noise_toggle.value = false
        else
          tmp.SAMPLE_NOISE_BOOL = true
          vbv.noise_toggle.value = true
        end
      end
    }
  else
    rnt:remove_midi_mapping("MX:Noise_toggle")
  end

  if not rnt:has_midi_mapping("MX:Noise_selector") then
    rnt:add_midi_mapping{
      name="MX:Noise_selector",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 0, #NOISES)
        vbv.noise_popup.value = val
        tmp.SAMPLE_NOISE_TYPE = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:Noise_selector")
  end

  if not rnt:has_midi_mapping("MX:Noise_amount") then
    rnt:add_midi_mapping{
      name="MX:Noise_amount",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 0, def.SAMPLE_MAX_NOISE)
        vbv.noise_slider.value = val
        vbv.noise_box.value = val
        tmp.SAMPLE_NOISE_AMOUNT = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:Noise_amount")
  end

  ------------------------- FILTERS --------------------------------------
  if not rnt:has_midi_mapping("MX:Filter_toggle") then
    rnt:add_midi_mapping{
      name="MX:Filter_toggle",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 0, 1)
        if val < 1 then
          tmp.SAMPLE_FILTER_TOGGLE = false
          vbv.filter_toggle.value = false
        else
          tmp.SAMPLE_FILTER_TOGGLE = true
          vbv.filter_toggle.value = true
        end
      end
    }
  else
    rnt:remove_midi_mapping("MX:Filter_toggle")
  end


  ------------------------- SAMPLE LEN -----------------------------------

  if not rnt:has_midi_mapping("MX:SAMPLE_LEN_selector") then
    rnt:add_midi_mapping{
      name="MX:SAMPLE_LEN_selector",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, #BUFFERS)
        vbv.framepopup.value = val
        tmp.SAMPLE_POPUP = val
        tmp.SAMPLE_FRAMES = FRAMES[tmp.SAMPLE_POPUP]
      end
    }
  else
    rnt:remove_midi_mapping("MX:SAMPLE_LEN_selector")
  end

  ----------------------------- OPERATIONS -------------------------------

  if not rnt:has_midi_mapping("MX:OP1_selector") then
    rnt:add_midi_mapping{
      name="MX:OP1_selector",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, #OPERATIONS)
        vbv.op1.value = val
        tmp.OP1 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OP1_selector")
  end

  if not rnt:has_midi_mapping("MX:OP2_selector") then
    rnt:add_midi_mapping{
      name="MX:OP2_selector",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 1, #OPERATIONS)
        vbv.op2.value = val
        tmp.OP2 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:OP2_selector")
  end

  ---------------------------- GAUSSIANS ------------------------------

  if not rnt:has_midi_mapping("MX:Gaussian_toggle") then
    rnt:add_midi_mapping{
      name="MX:Gaussian_toggle",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, 0, 1)
        if val == 1 then
          vbv.gaussian_on_off.value = true
          tmp.GAUSSIAN_ON_OFF = true
        else
          vbv.gaussian_on_off.value = false
          tmp.GAUSSIAN_ON_OFF = false
        end
      end
    }
  else
    rnt:remove_midi_mapping("MX:Gaussian_toggle")
  end

  if not rnt:has_midi_mapping("MX:G1_rising") then
    rnt:add_midi_mapping{
      name="MX:G1_rising",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_V_MIN, def.GAUSSIAN_V_MAX)
        vbv.gauss_v1.value = val
        tmp.GAUSSIAN_V1 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G1_rising")
  end

  if not rnt:has_midi_mapping("MX:G2_rising") then
    rnt:add_midi_mapping{
      name="MX:G2_rising",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_V_MIN, def.GAUSSIAN_V_MAX)
        vbv.gauss_v2.value = val
        tmp.GAUSSIAN_V2 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G2_rising")
  end

  if not rnt:has_midi_mapping("MX:G3_rising") then
    rnt:add_midi_mapping{
      name="MX:G3_rising",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_V_MIN, def.GAUSSIAN_V_MAX)
        vbv.gauss_v3.value = val
        tmp.GAUSSIAN_V3 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G3_rising")
  end

  if not rnt:has_midi_mapping("MX:G4_rising") then
    rnt:add_midi_mapping{
      name="MX:G4_rising",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_V_MIN, def.GAUSSIAN_V_MAX)
        vbv.gauss_v4.value = val
        tmp.GAUSSIAN_V4 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G4_rising")
  end

  if not rnt:has_midi_mapping("MX:G5_rising") then
    rnt:add_midi_mapping{
      name="MX:G5_rising",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_V_MIN, def.GAUSSIAN_V_MAX)
        vbv.gauss_v5.value = val
        tmp.GAUSSIAN_V5 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G5_rising")
  end

  if not rnt:has_midi_mapping("MX:G1_dancing") then
    rnt:add_midi_mapping{
      name="MX:G1_dancing",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_N_MIN, def.GAUSSIAN_N_MAX)
        vbv.gauss_n1.value = val
        tmp.GAUSSIAN_N1 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G1_dancing")
  end

  if not rnt:has_midi_mapping("MX:G2_dancing") then
    rnt:add_midi_mapping{
      name="MX:G2_dancing",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_N_MIN, def.GAUSSIAN_N_MAX)
        vbv.gauss_n2.value = val
        tmp.GAUSSIAN_N2 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G2_dancing")
  end

  if not rnt:has_midi_mapping("MX:G3_dancing") then
    rnt:add_midi_mapping{
      name="MX:G3_dancing",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_N_MIN, def.GAUSSIAN_N_MAX)
        vbv.gauss_n3.value = val
        tmp.GAUSSIAN_N3 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G3_dancing")
  end

  if not rnt:has_midi_mapping("MX:G4_dancing") then
    rnt:add_midi_mapping{
      name="MX:G4_dancing",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_N_MIN, def.GAUSSIAN_N_MAX)
        vbv.gauss_n4.value = val
        tmp.GAUSSIAN_N4 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G4_dancing")
  end

  if not rnt:has_midi_mapping("MX:G5_dancing") then
    rnt:add_midi_mapping{
      name="MX:G5_dancing",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_N_MIN, def.GAUSSIAN_N_MAX)
        vbv.gauss_n5.value = val
        tmp.GAUSSIAN_N5 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G5_dancing")
  end

  if not rnt:has_midi_mapping("MX:G1_expands") then
    rnt:add_midi_mapping{
      name="MX:G1_expands",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_S_MIN, def.GAUSSIAN_S_MAX)
        vbv.gauss_s1.value = val
        tmp.GAUSSIAN_S1 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G1_expands")
  end

  if not rnt:has_midi_mapping("MX:G2_expands") then
    rnt:add_midi_mapping{
      name="MX:G2_expands",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_S_MIN, def.GAUSSIAN_S_MAX)
        vbv.gauss_s2.value = val
        tmp.GAUSSIAN_S2 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G2_expands")
  end

  if not rnt:has_midi_mapping("MX:G3_expands") then
    rnt:add_midi_mapping{
      name="MX:G3_expands",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_S_MIN, def.GAUSSIAN_S_MAX)
        vbv.gauss_s3.value = val
        tmp.GAUSSIAN_S3 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G3_expands")
  end

  if not rnt:has_midi_mapping("MX:G4_expands") then
    rnt:add_midi_mapping{
      name="MX:G4_expands",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_S_MIN, def.GAUSSIAN_S_MAX)
        vbv.gauss_s4.value = val
        tmp.GAUSSIAN_S4 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G4_expands")
  end

  if not rnt:has_midi_mapping("MX:G5_expands") then
    rnt:add_midi_mapping{
      name="MX:G5_expands",
      invoke=function(msg)
        local val = map_from_to(msg.int_value, 0, 127, def.GAUSSIAN_S_MIN, def.GAUSSIAN_S_MAX)
        vbv.gauss_s5.value = val
        tmp.GAUSSIAN_S5 = val
      end
    }
  else
    rnt:remove_midi_mapping("MX:G5_expands")
  end
end
-------------------------------- this is the END --------------------------------------------