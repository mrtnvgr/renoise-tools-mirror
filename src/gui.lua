--[[----------------------------------------------------------------
Macuilxochitl GUI file                                             -
]]------------------------------------------------------------------

--require "src/generators"


OPERATIONS = {"Nope","Add", "Sub", "Mul", "Div", "Min", "Max", "Mod"}
WAVES = {"Saw", "Sine", "Square", "Triangle","Sin to Saw", "Sin to Square", "Sin to Tan", "ArcCosine"}
BUFFERS = {"84", "168", "337", "674", "1348", "2697", "5395", "10790"}
NOTES = {"C4", "C5", "C6"}
FILTERS = {"Lowpass filter", "Highpass filter", "Bandpass filter","Notch filter", "Allpass filter",
           "PeakEQ filter", "LowShelf filter", "HighShelf filter", "Formant filter", "Bitcrusher"}
NOISES = {"White noise", "Pink noise", "Brownian noise"}
FINISHERS = {"None", "Waveshaper S1", "Waveshaper S2", "Waveshaper S3", "Waveshaper S4",
             "Gloubi Boulga", "Foldback"}

--[[----------------------------------------------------------------
gui constants                                                      -
]]------------------------------------------------------------------

DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
DEFAULT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
DEFAULT_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
MINISLIDER_HEIGHT = 12
SELECTED_PAGE = 3
MENU_BUTTON_WIDTH = 32
MENU_BUTTON_HEIGHT= 24
OSC_BUTTON_WH = 19
VALUEBOX_HEIGHT = 20


function key_handler(dialog, key)
  -- all keys go through
  return key
end

--[[----------------------------------------------------------------
Show GUI                                                           -
]]------------------------------------------------------------------


function show_gui()

--[[----------------------------------------------------------------
Create OSC 1 settings                                              -
]]------------------------------------------------------------------
  local osc_1_gui = vb:column{
    id="osc1panel",
    style="group",
    margin=DEFAULT_MARGIN,
    spacing=DEFAULT_SPACING,
    height = DEFAULT_HEIGHT,
    width=320,
    vb:row{
      vb:text{
        text="Huehuecóyotl",
        font="bold",
        style="strong",
        width=90,
      },
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:popup{
          id="osc1type",
          midi_mapping="MX:OSC1_selector",
          width=105,
          items=WAVES,
          value=tmp.SAMPLE_TYPE_1,
          notifier = function(wave)
            tmp.SAMPLE_TYPE_1 = wave
            OSC1.class = tmp.SAMPLE_TYPE_1
            if wave == 8 then
              -- generate only noise
              vb.views.noise_toggle.value = true
              tmp.SAMPLE_NOISE_BOOL = true
            end
            redraw_sample()
          end
        },
        vb:popup{
          id="osc1note",
          width=50,
          items=NOTES,
          value=1,
          notifier=function(note)
            
            if note > 2 then
              tmp.SAMPLE_FREQUENCY_1 = 2 ^ (note-1)
            else
              tmp.SAMPLE_FREQUENCY_1 = note
            end
            vb.views.freq1slider.value=tmp.SAMPLE_FREQUENCY_1
            vb.views.freq1box.value=tmp.SAMPLE_FREQUENCY_1
            redraw_sample()
          end
        },
      },
    },
    -- --------------------------------------- frequency OSC 1
    vb:row{
      vb:text{text="Period", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=230,
        spacing=5,
        vb:slider{
          --height=VALUEBOX_HEIGHT,
          id = "freq1slider",
          midi_mapping="MX:OSC1_period",
          width=115,
          min=def.SAMPLE_MIN_PERIOD,
          max=def.SAMPLE_MAX_PERIOD,
          value=tmp.SAMPLE_FREQUENCY_1,
          notifier = function(freq)
            tmp.SAMPLE_FREQUENCY_1 = freq
            OSC1.frequency = tmp.SAMPLE_FREQUENCY_1
            vb.views.freq1box.value=OSC1.frequency
            redraw_sample()
          end
        },
        vb:valuefield{
          id="freq1box",
          width=50,
          value=tmp.SAMPLE_FREQUENCY_1,
          min=def.SAMPLE_MIN_PERIOD,
          max= def.SAMPLE_MAX_PERIOD,
          notifier = function(freq)
            tmp.SAMPLE_FREQUENCY_1 = freq
            OSC1.frequency = tmp.SAMPLE_FREQUENCY_1
            vb.views.freq1slider.value = OSC1.frequency
            redraw_sample()
          end
        },
      },
    },
    -- --------------------------------------- amplitude OSC 1
    vb:row{
      vb:text{text="Amplitude", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=230,
        spacing=5,
        vb:slider{
          id = "amp1slider",
          midi_mapping="MX:OSC1_amplitude",
          width=115,
          min=def.SAMPLE_MIN_AMPLITUDE,
          max=def.SAMPLE_MAX_AMPLITUDE,
          value=tmp.SAMPLE_AMPLITUDE_1,
          notifier = function(amplitude)
            tmp.SAMPLE_AMPLITUDE_1 = amplitude
            OSC1.amplitude = tmp.SAMPLE_AMPLITUDE_1
            vb.views.amp1box.value = OSC1.amplitude
            redraw_sample()
          end
        },
        vb:valuefield{
          id="amp1box",
          width=50,
          value=tmp.SAMPLE_AMPLITUDE_1,
          min=def.SAMPLE_MIN_AMPLITUDE,
          max= def.SAMPLE_MAX_AMPLITUDE,
          notifier = function(amp)
            tmp.SAMPLE_AMPLITUDE_1 = amp
            OSC1.amplitude = tmp.SAMPLE_AMPLITUDE_1
            vb.views.amp1slider.value = OSC1.amplitude
            redraw_sample()
          end
        },
      },
    },
    -- ----------------------------------------- phase OSC 1
    vb:row{
      vb:text{text="Phase", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:valuebox{
          id = "phase1slider",
          midi_mapping="MX:OSC1_phase",
          width=160,
          min=-def.SAMPLE_MAX_PHASE,
          max=def.SAMPLE_MAX_PHASE,
          value=tmp.SAMPLE_PHASE_1,
          steps={1, 10},
          notifier = function(phase)
            tmp.SAMPLE_PHASE_1 = phase
            OSC1.phase = tmp.SAMPLE_PHASE_1
            redraw_sample()
          end
        },
      },
    },
    ------------------------------------------------ Detail OSC1
    vb:row{
      id="osc1detail",
      vb:text{text="Detail", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:valuebox{
          id = "detail1slider",
          midi_mapping="MX:OSC1_detail",
          width=160,
          min=1,
          max=128,
          value=tmp.SAMPLE_DETAIL_1,
          steps={1, 10},
          notifier = function(detail)
            tmp.SAMPLE_DETAIL_1 = math.floor(detail)
            OSC1.detail = tmp.SAMPLE_DETAIL_1
            redraw_sample()
          end
        },
      },
    },
  }

--[[--------------------------------------------------------------
Oscilator 2 Settings                                             -
]]----------------------------------------------------------------
  local osc_2_gui = vb:column{
    id="osc2panel",
    style="group",
    margin=DEFAULT_MARGIN,
    width=325,
    vb:horizontal_aligner{
      mode="left",
      vb:text{
        text="Ah-Xoc-Xin",
        font="bold",
        style="strong",
        width=90,
      },
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:popup{
          id="osc2type",
          midi_mapping="MX:OSC2_selector",
          width=105,
          items=WAVES,
          value=tmp.SAMPLE_TYPE_2,
          notifier = function(wave)
            tmp.SAMPLE_TYPE_2 = wave
            OSC2.class = tmp.SAMPLE_TYPE_2
            redraw_sample()
          end
        },
        vb:popup{
          id="osc2note",
          width=50,
          items=NOTES,
          value=1,
          notifier=function(note)
            
            if note > 2 then
              tmp.SAMPLE_FREQUENCY_2 = 2 ^ (note-1)
            else
              tmp.SAMPLE_FREQUENCY_2 = note
            end
            vb.views.freq2slider.value=tmp.SAMPLE_FREQUENCY_2
            vb.views.freq2box.value=tmp.SAMPLE_FREQUENCY_2
            redraw_sample()
          end
        },
      },
    },
    -- ---------------------------------------- frequency osc 2
    vb:row{
      vb:text{text="Period", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:checkbox{
          id="osc2freqmod",
          width=18,
          height=18,
          value=false,
          notifier = function(bool)
            OSC2.modulate_freq=bool
            tmp.OSC2_FREQUENCY_MOD = bool
            redraw_sample()
          end
        },
        vb:slider{
          id = "freq2slider",
          midi_mapping="MX:OSC2_period",
          width=105,
          min=def.SAMPLE_MIN_PERIOD,
          max=def.SAMPLE_MAX_PERIOD,
          value=tmp.SAMPLE_FREQUENCY_2,
          notifier = function(freq)
            tmp.SAMPLE_FREQUENCY_2 = freq
            OSC2.frequency = tmp.SAMPLE_FREQUENCY_2
            vb.views.freq2box.value=OSC2.frequency
            redraw_sample()
          end
        },
        vb:valuefield{
          id="freq2box",
          width=50,
          min=def.SAMPLE_MIN_PERIOD,
          max=def.SAMPLE_MAX_PERIOD,
          value=tmp.SAMPLE_FREQUENCY_2,
          notifier=function(freq)
            tmp.SAMPLE_FREQUENCY_2 = freq
            OSC2.frequency=tmp.SAMPLE_FREQUENCY_2
            vb.views.freq2slider.value = OSC2.frequency
            redraw_sample()
          end
        },
      },
    },
    -- ----------------------------------------- amplitude OSC 2
    vb:row{
      vb:text{text="Amplitude", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:checkbox{
          id="osc2ampmod",
          width=18,
          height=18,
          value=false,
          notifier = function(bool)
            OSC2.modulate_amp=bool
            tmp.OSC2_AMPLITUDE_MOD = bool
            redraw_sample()
          end
        },
        vb:slider{
          id = "amp2slider",
          midi_mapping="MX:OSC2_amplitude",
          width=105,
          min=def.SAMPLE_MIN_AMPLITUDE,
          max=def.SAMPLE_MAX_AMPLITUDE,
          value=tmp.SAMPLE_AMPLITUDE_2,
          notifier = function(amplitude)
            tmp.SAMPLE_AMPLITUDE_2 = amplitude
            OSC2.amplitude = tmp.SAMPLE_AMPLITUDE_2
            vb.views.amp2box.value = OSC2.amplitude
            redraw_sample()
          end
        },
        vb:valuefield{
          id="amp2box",
          width=50,
          min=def.SAMPLE_MIN_AMPLITUDE,
          max=def.SAMPLE_MAX_AMPLITUDE,
          value=tmp.SAMPLE_AMPLITUDE_2,
          notifier=function(amp)
            tmp.SAMPLE_AMPLITUDE_2 = amp
            OSC2.amplitude=tmp.SAMPLE_AMPLITUDE_2
            vb.views.amp2slider.value = OSC2.amplitude
            redraw_sample()
          end
        },
      },
    },
    -- ------------------------------------------- phase OSC 2
    vb:row{
      vb:text{text="Phase", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:checkbox{
          id="osc2phasemod",
          width=18,
          height=18,
          value=false,
          notifier = function(bool)
            OSC2.modulate_phase=bool
            tmp.OSC2_PHASE_MOD = bool
            redraw_sample()
          end
        },
        vb:valuebox{
          id = "phase2slider",
          midi_mapping="MX:OSC2_phase",
          width=160,
          min=-def.SAMPLE_MAX_PHASE,
          max=def.SAMPLE_MAX_PHASE,
          value=tmp.SAMPLE_PHASE_2,
          steps={1, 10},
          notifier = function(phase)
            tmp.SAMPLE_PHASE_2 = phase
            OSC2.phase = tmp.SAMPLE_PHASE_2
            redraw_sample()
          end
        },
      },
    },
    ------------------------------------------------ Detail OSC2
    vb:row{
      id="osc2detail",
      vb:text{text="Detail", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:valuebox{
          id = "detail2slider",
          midi_mapping="MX:OSC2_detail",
          width=160,
          min=1,
          max=128,
          value=tmp.SAMPLE_DETAIL_2,
          steps={1, 10},
          notifier = function(detail)
            tmp.SAMPLE_DETAIL_2 = math.floor(detail)
            OSC2.detail = tmp.SAMPLE_DETAIL_2
            redraw_sample()
          end
        },
      },
    },
  }

--[[----------------------------------------------------------------
Create OSC 3 Settings                                              -
]]------------------------------------------------------------------
  local osc_3_gui = vb:column{
    id="osc3panel",
    style="group",
    margin=DEFAULT_MARGIN,
    width=325,
    vb:horizontal_aligner{
      mode="left",
      vb:text{
        text="Xochiquetzal",
        font="bold",
        style="strong",
        width=90,
      },
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:popup{
          id="osc3type",
          midi_mapping="MX:OSC3_selector",
          width=105,
          items=WAVES,
          value=tmp.SAMPLE_TYPE_3,
          notifier = function(wave)
            tmp.SAMPLE_TYPE_3 = wave
            OSC3.class = tmp.SAMPLE_TYPE_3
            redraw_sample()
          end
        },
        vb:popup{
          id="osc3note",
          width=50,
          items=NOTES,
          value=1,
          notifier=function(note)
            
            if note > 2 then
              tmp.SAMPLE_FREQUENCY_3 = 2 ^ (note-1)
            else
              tmp.SAMPLE_FREQUENCY_3 = note
            end
            vb.views.freq3slider.value=tmp.SAMPLE_FREQUENCY_3
            vb.views.freq3box.value=tmp.SAMPLE_FREQUENCY_3
            redraw_sample()
          end
        },
      },
    },
    -- -------------------------------------------frequency OSC 3
    vb:row{
      vb:text{text="Period", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:checkbox{
          id="osc3freqmod",
          width=18,
          height=18,
          value=false,
          notifier = function(bool)
            OSC3.modulate_freq=bool
            tmp.OSC3_FREQUENCY_MOD = bool
            redraw_sample()
          end
        },
        vb:slider{
          id = "freq3slider",
          midi_mapping="MX:OSC3_period",
          width=105,
          min=def.SAMPLE_MIN_PERIOD,
          max=def.SAMPLE_MAX_PERIOD,
          value=tmp.SAMPLE_FREQUENCY_3,
          notifier = function(freq)
            tmp.SAMPLE_FREQUENCY_3 = freq
            OSC3.frequency = tmp.SAMPLE_FREQUENCY_3
            vb.views.freq3box.value=OSC3.frequency
            redraw_sample()
          end
        },
        vb:valuefield{
          id="freq3box",
          width=50,
          min=def.SAMPLE_MIN_PERIOD,
          max=def.SAMPLE_MAX_PERIOD,
          value=tmp.SAMPLE_FREQUENCY_3,
          notifier=function(freq)
            tmp.SAMPLE_FREQUENCY_3 = freq
            OSC3.frequency=tmp.SAMPLE_FREQUENCY_3
            vb.views.freq3slider.value = OSC3.frequency
            redraw_sample()
          end
        },
      },
    },
    -- -------------------------------------------- amplitude OSC 3
    vb:row{
      vb:text{text="Amplitude", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:checkbox{
          id="osc3ampmod",
          width=18,
          height=18,
          value=false,
          notifier = function(bool)
            OSC3.modulate_amp=bool
            tmp.OSC3_AMPLITUDE_MOD = bool
            redraw_sample()
          end
        },
        vb:slider{
          id = "amp3slider",
          midi_mapping="MX:OSC3_amplitude",
          width=105,
          min=def.SAMPLE_MIN_AMPLITUDE,
          max=def.SAMPLE_MAX_AMPLITUDE,
          value=tmp.SAMPLE_AMPLITUDE_3,
          notifier = function(amplitude)
            tmp.SAMPLE_AMPLITUDE_3 = amplitude
            OSC3.amplitude = tmp.SAMPLE_AMPLITUDE_3
            vb.views.amp3box.value = OSC3.amplitude
            redraw_sample()
          end
        },
        vb:valuefield{
          id="amp3box",
          width=50,
          min=def.SAMPLE_MIN_AMPLITUDE,
          max=def.SAMPLE_MAX_AMPLITUDE,
          value=tmp.SAMPLE_AMPLITUDE_3,
          notifier=function(amp)
            tmp.SAMPLE_AMPLITUDE_3 = amp
            OSC3.amplitude=tmp.SAMPLE_AMPLITUDE_3
            vb.views.amp3slider.value = OSC3.amplitude
            redraw_sample()
          end
        },
      },
    },
    -- -------------------------------------------- phase OSC 3
    vb:row{
      vb:text{text="Phase", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:checkbox{
          id="osc3phasemod",
          width=18,
          height=18,
          value=false,
          notifier = function(bool)
            OSC3.modulate_phase=bool
            tmp.OSC3_PHASE_MOD = bool
            redraw_sample()
          end
        },
        vb:valuebox{
          id = "phase3slider",
          midi_mapping="MX:OSC3_phase",
          width=160,
          min=-def.SAMPLE_MAX_PHASE,
          max=def.SAMPLE_MAX_PHASE,
          value=tmp.SAMPLE_PHASE_3,
          steps={1, 10},
          notifier = function(phase)
            tmp.SAMPLE_PHASE_3 = phase
            OSC3.phase = tmp.SAMPLE_PHASE_3
            redraw_sample()
          end
        },
      },
    },
    ------------------------------------------------ Detail OSC 3
    vb:row{
      id="osc3detail",
      vb:text{text="Detail", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:valuebox{
          id = "detail3slider",
          midi_mapping="MX:OSC3_detail",
          width=160,
          min=1,
          max=128,
          value=tmp.SAMPLE_DETAIL_3,
          steps={1, 10},
          notifier = function(detail)
            tmp.SAMPLE_DETAIL_3 = math.floor(detail)
            OSC3.detail = tmp.SAMPLE_DETAIL_3
            redraw_sample()
          end
        },
      },
    },
  }
      
--[[-------------------------------------------------------------------------------
Noisy Controls                                                                    -
]]---------------------------------------------------------------------------------
  local noisy_gui = vb:column{
    style="group",
    margin=DEFAULT_MARGIN,
    width=322,
    vb:row{
      vb:horizontal_aligner{
        spacing=5,
        mode="center",
        vb:text{
          width=122,
          id="noisy_message",
          text="Sak Nik",
          font="bold",
          style="strong",
        },
        vb:checkbox{
          id="noise_toggle",
          width=18,
          height=18,
          value=tmp.SAMPLE_NOISE_BOOL,
          notifier=function(bool)
            tmp.SAMPLE_NOISE_BOOL = bool
            vb.views.noise_slider.value = def.SAMPLE_MIN_NOISE
            vb.views.noise_box.value = def.SAMPLE_MIN_NOISE
            tmp.SAMPLE_NOISE_AMOUNT = def.SAMPLE_MIN_NOISE
            Regenerate_noise()
            redraw_sample()
          end
        },
        vb:popup{
          id="noise_popup",
          width=160,
          items=NOISES,
          value=tmp.SAMPLE_NOISE_TYPE,
          notifier = function(typ)
            tmp.SAMPLE_NOISE_TYPE = typ
            Regenerate_noise()
            redraw_sample()
          end
        },
      },
    },
    vb:row{
      vb:text{text="Amount", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:slider{
          width=105,
          id="noise_slider",
          midi_mapping="MX:Noise_amount",
          min=def.SAMPLE_MIN_NOISE,
          max=def.SAMPLE_MAX_NOISE,
          steps={0.001, 0.01},
          value=tmp.SAMPLE_NOISE_AMOUNT,
          notifier=function(noise)
            tmp.SAMPLE_NOISE_AMOUNT = noise
            vb.views.noise_box.value = tmp.SAMPLE_NOISE_AMOUNT
            --Regenerate_noise()
            customize_noise()
            redraw_sample()
          end
        },
        vb:valuefield{
          id="noise_box",
          width=50,
          min=def.SAMPLE_MIN_NOISE,
          max=def.SAMPLE_MAX_NOISE,
          value=tmp.SAMPLE_NOISE_AMOUNT,
          notifier=function(amount)
            tmp.SAMPLE_NOISE_AMOUNT=amount
            vb.views.noise_slider.value=tmp.SAMPLE_NOISE_AMOUNT
            --Regenerate_noise()
            customize_noise()
            redraw_sample()
          end 
        },
      },
    },
  }


--[[-------------------------------------------------------------------------------
Filter Controls                                                                    -
]]---------------------------------------------------------------------------------
  local filter_gui = vb:column{
    style="group",
    margin=DEFAULT_MARGIN,
    width=322,
    vb:row{
      vb:horizontal_aligner{
        spacing=5,
        mode="center",
        vb:text{
          width=122,
          text="Atabey",
          font="bold",
          style="strong",
        },
        vb:checkbox{
          id="filter_toggle",
          midi_mapping="MX:Filter_toggle",
          width=18,
          height=18,
          value=tmp.SAMPLE_FILTER_TOGGLE,
          notifier=function(bool)
            tmp.SAMPLE_FILTER_TOGGLE = bool
            redraw_sample()
          end
        },
        vb:popup{
          id="filter_popup",
          midi_mapping="MX:Filter_selector",
          width=160,
          items=FILTERS,
          value=tmp.SAMPLE_FILTER_TYPE,
          notifier = function(typ)
            tmp.SAMPLE_FILTER_TYPE = typ
            if typ == 9 then  -- vowel
              vb.views.filter_freq_row.visible=false
              vb.views.filter_quality_row.visible=false
              vb.views.filter_gain_row.visible=false
              vb.views.filter_wet_row.visible=false
              vb.views.filter_vowel_row.visible=true
            else
              vb.views.filter_freq_row.visible=true
              vb.views.filter_quality_row.visible=true
              vb.views.filter_gain_row.visible=true
              vb.views.filter_wet_row.visible=true
              vb.views.filter_vowel_row.visible=false
            end
            redraw_sample()
          end
        },
      },
    },
    vb:row{
      id="filter_freq_row",
      vb:text{id="filter_freq_text", text="Frequency", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:slider{
          width=105,
          id="filter_freq_slider",
          midi_mapping="MX:Filter_freq",
          min=def.SAMPLE_MIN_FILTER_FREQ,
          max=def.SAMPLE_MAX_FILTER_FREQ,
          steps={0.001, 0.01},
          value=tmp.SAMPLE_FILTER_FREQ,
          notifier=function(freq)
            tmp.SAMPLE_FILTER_FREQ = freq
            vb.views.filter_freq_box.value = tmp.SAMPLE_FILTER_FREQ
            redraw_sample()
          end
        },
        vb:valuefield{
          id="filter_freq_box",
          width=50,
          min=def.SAMPLE_MIN_FILTER_FREQ,
          max=def.SAMPLE_MAX_FILTER_FREQ,
          value=tmp.SAMPLE_FILTER_FREQ,
          notifier=function(freq)
            tmp.SAMPLE_FILTER_FREQ=freq
            vb.views.filter_freq_slider.value=tmp.SAMPLE_FILTER_FREQ
            redraw_sample()
          end 
        },
      },
    },
    vb:row{
      id="filter_quality_row",
      vb:text{text="Quality", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:slider{
          width=105,
          id="filter_quality_slider",
          midi_mapping="MX:Filter_quality",
          min=def.SAMPLE_MIN_FILTER_QUALITY,
          max=def.SAMPLE_MAX_FILTER_QUALITY,
          steps={1, 5},
          value=tmp.SAMPLE_FILTER_QUALITY,
          notifier=function(quality)
            tmp.SAMPLE_FILTER_QUALITY = math.floor(quality)
            vb.views.filter_quality_box.value = tmp.SAMPLE_FILTER_QUALITY
            redraw_sample()
          end
        },
        vb:valuefield{
          id="filter_quality_box",
          width=50,
          min=def.SAMPLE_MIN_FILTER_QUALITY,
          max=def.SAMPLE_MAX_FILTER_QUALITY,
          value=tmp.SAMPLE_FILTER_QUALITY,
          notifier=function(quality)
            tmp.SAMPLE_FILTER_QUALITY=math.floor(quality)
            vb.views.filter_quality_slider.value=tmp.SAMPLE_FILTER_QUALITY
            redraw_sample()
          end 
        },
      },
    },
    vb:row{
      id="filter_gain_row",
      vb:text{text="Gain", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:slider{
          width=105,
          id="filter_gain_slider",
          midi_mapping="MX:Filter_gain",
          min=def.SAMPLE_MIN_FILTER_GAIN,
          max=def.SAMPLE_MAX_FILTER_GAIN,
          steps={1, 5},
          value=tmp.SAMPLE_FILTER_GAIN,
          notifier=function(gain)
            tmp.SAMPLE_FILTER_GAIN = math.floor(gain)
            vb.views.filter_gain_box.value = tmp.SAMPLE_FILTER_GAIN
            redraw_sample()
          end
        },
        vb:valuefield{
          id="filter_gain_box",
          width=50,
          min=def.SAMPLE_MIN_FILTER_GAIN,
          max=def.SAMPLE_MAX_FILTER_GAIN,
          value=tmp.SAMPLE_FILTER_GAIN,
          notifier=function(gain)
            tmp.SAMPLE_FILTER_GAIN=math.floor(gain)
            vb.views.filter_gain_slider.value=tmp.SAMPLE_FILTER_GAIN
            redraw_sample()
          end 
        },
      },
    },
    vb:row{
      id="filter_wet_row",
      vb:text{text="Wet", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:slider{
          width=105,
          id="filter_wet_slider",
          midi_mapping="MX:Filter_wet",
          min=def.SAMPLE_MIN_FILTER_WET,
          max=def.SAMPLE_MAX_FILTER_WET,
          steps={0.001, 0.01},
          value=tmp.SAMPLE_FILTER_WET,
          notifier=function(wet)
            tmp.SAMPLE_FILTER_WET = wet
            vb.views.filter_wet_box.value = tmp.SAMPLE_FILTER_WET
            redraw_sample()
          end
        },
        vb:valuefield{
          id="filter_wet_box",
          width=50,
          min=def.SAMPLE_MIN_FILTER_WET,
          max=def.SAMPLE_MAX_FILTER_WET,
          value=tmp.SAMPLE_FILTER_WET,
          notifier=function(wet)
            tmp.SAMPLE_FILTER_WET=wet
            vb.views.filter_wet_slider.value=tmp.SAMPLE_FILTER_WET
            redraw_sample()
          end 
        },
      },
    },
    vb:row{
      id="filter_vowel_row",
      vb:text{text="Vowels [AEIOU]", align="left", width=90},
      vb:horizontal_aligner{
        mode="right",
        width=220,
        spacing=5,
        vb:valuebox{
          width=160,
          id="filter_vowel",
          midi_mapping="MX:Filter_vowel",
          min=1,
          max=5,
          steps={1, 1},
          value=tmp.SAMPLE_FILTER_VOWEL,
          notifier=function(vowel)
            tmp.SAMPLE_FILTER_VOWEL = vowel
            redraw_sample()
          end
        },
      },
    },
  }

--[[------------------------------------------------------------------------------------
Sample Frames control                                                                  -
]]--------------------------------------------------------------------------------------
  local frames_gui = vb:column{
    style="group",
    margin=DEFAULT_MARGIN,
    width=322,
    vb:row{
      vb:text{text="Sample frames", align="left", width=80},
      vb:horizontal_aligner{
        width=230,
        mode="right",
        spacing=5,
        vb:popup{
          id="framepopup",
          midi_mapping="MX:SAMPLE_LEN_selector",
          width=75,
          items=BUFFERS,
          value=tmp.SAMPLE_POPUP,
          notifier = function(amount)

            local amount = math.floor(amount)

            if MAIN_SAMPLE then
              read_info_from_sample(MAIN_SAMPLE, MAIN_INSTRUMENT)
            end

            local old_popup = tmp.SAMPLE_POPUP
            tmp.SAMPLE_POPUP = amount
            
            tmp.SAMPLE_FRAMES = tonumber(BUFFERS[tmp.SAMPLE_POPUP])
            vb.views.framebox.value = tmp.SAMPLE_FRAMES
            --print("Klik " .. tostring(tmp.SAMPLE_FRAMES))

            -- this is quick hack :(
            local note = vb.views.osc1note.value
         
            if amount == 1 then
              NOTES = {"C4", "C5", "C6",}
            elseif amount == 2 then
              NOTES = {"C3", "C4", "C5", "C6"}
            elseif amount == 3 then
              NOTES = {"C2", "C3", "C4", "C5", "C6", "C7"}
            elseif amount == 4 then
              NOTES = {"C1", "C2", "C3", "C4", "C5", "C6", "C7"}
            elseif amount == 5 then
              NOTES = {"C0", "C1", "C2", "C3", "C4", "C5", "C6", "C7"}
            elseif amount == 6 then
              NOTES = {"C-1", "C0", "C1", "C2", "C3", "C4", "C5", "C6", "C7"}
            elseif amount == 7 then
              NOTES = {"C-2", "C-1", "C0", "C1", "C2", "C3", "C4", "C5", "C6"}
            elseif amount == 8 then
              NOTES = {"C-3", "C-2", "C-1", "C0", "C1", "C2", "C3", "C4", "C5"}
            end

            --if amount > old_popup then
            --  note = note + (old_popup - amount)
            --elseif amount < old_popup then
            --  note = note - (old_popup - amount)
            --end

            vb.views.osc1note.value = note
           
            vb.views.osc1note.items=NOTES
            vb.views.osc2note.items=NOTES
            vb.views.osc3note.items=NOTES
            Regenerate_noise()
            redraw_sample("new_patch")
          end
        },
        vb:valuebox{
          id="framebox",
          width=80,
          min=1,
          max=44100,
          value=tmp.SAMPLE_FRAMES,
          steps={1, 10},
          notifier = function(frames)
            tmp.SAMPLE_FRAMES = frames
            Regenerate_noise()
            redraw_sample("new_patch")
          end
        }
      },
    },
    --[[----------------------------------------------------------------------------
    vb:space{height=5},
    vb:row{
      vb:text{text="Channel", width=70},
      vb:horizontal_aligner{
        mode="right",
        width=240,
        vb:switch{
          id="sample_channel_switch",
          width=220,
          height=22,
          items={"Mono", "Left", "Right"},
          value=tmp.SAMPLE_BUFFER_SELECTOR,
          notifier = function(channel_type)
          end 
        },
      },
    },
    ]]------------------------------------------------------------------------------------
  }

--[[--------------------------------------------------------------------------------------
Operation control                                                                        -
]]----------------------------------------------------------------------------------------
  local operator_gui = vb:column{
    style="group",
    margin=DEFAULT_MARGIN,
    width=326,
    vb:horizontal_aligner{
      mode="center",
      vb:row{
        spacing=3,
        vb:text{text="Op1->", align="left"},
        vb:popup{
          midi_mapping="MX:OP1_selector",
          id="op1",
          width=90,
          items=OPERATIONS,
          value=tmp.OP1,
          notifier=function(value)
            tmp.OP1=tonumber(value)
            redraw_sample()
          end
        },
        vb:text{text="Op2->", align="left"},
        vb:popup{
          id="op2",
          midi_mapping="MX:OP2_selector",
          width=90,
          items=OPERATIONS,
          value = tmp.OP2,
          notifier=function(value)
            tmp.OP2 = tonumber(value)
            redraw_sample()
          end
        },
        vb:text{text="Op3", align="left"},
      },
    },
  }

--[[--------------------------------------------------------------------------------------
GAUSSIAN CONTROL                                                                         -
]]----------------------------------------------------------------------------------------
  local gaussian_gui = vb:column{
    spacing=DEFAULT_SPACING,
    margin = DEFAULT_MARGIN,
    height = DEFAULT_HEIGHT,
    vb:row{
        vb:checkbox{
          id="gaussian_on_off",
          midi_mapping="MX:Gaussian_toggle",
          value=tmp.GAUSSIAN_ON_OFF,
          notifier=function(bool)
            tmp.GAUSSIAN_ON_OFF = bool
            redraw_sample()
          end
        },
        vb:text{
          style="strong",
          font="bold",
          text="Let the gods work together",
          width=130,
        },
      },
    vb:column{
      id="gods1",
      spacing=DEFAULT_SPACING,
      margin = DEFAULT_MARGIN,
      height = DEFAULT_HEIGHT,
      style="group",
      width=320,
      vb:vertical_aligner{
        mode="center",
        vb:row{
          vb:text{text="Huehuecóyotl rising", width=130},
          vb:slider{
            id="gauss_v1",
            midi_mapping="MX:G1_rising",
            --height=MINISLIDER_HEIGHT,
            width=170,
            min=def.GAUSSIAN_V_MIN,
            max=def.GAUSSIAN_V_MAX,
            value=tmp.GAUSSIAN_V1,
            notifier = function(value)
              tmp.GAUSSIAN_V1 = value
              redraw_sample()
            end
          },
        },
        vb:row{
          vb:text{text="Ah-Xoc-Xin rising", width=130},
          vb:slider{
            id="gauss_v2",
            midi_mapping="MX:G2_rising",
            --height=MINISLIDER_HEIGHT,
            width=170,
            min=def.GAUSSIAN_V_MIN,
            max=def.GAUSSIAN_V_MAX,
            value=tmp.GAUSSIAN_V2,
            notifier = function(value)
              tmp.GAUSSIAN_V2 = value
              redraw_sample()
            end
          },
        },
        vb:row{
          vb:text{text="Xochiquetzal rising", width=130},
          vb:slider{
            id="gauss_v3",
            midi_mapping="MX:G3_rising",
            --height=MINISLIDER_HEIGHT,
            width=170,
            min=def.GAUSSIAN_V_MIN,
            max=def.GAUSSIAN_V_MAX,
            value=tmp.GAUSSIAN_V3,
            notifier = function(value)
              tmp.GAUSSIAN_V3 = value
              redraw_sample()
            end
          },
        },
        vb:row{
          vb:text{text="Sak Nik rising", width=130},
          vb:slider{
            id="gauss_v4",
            midi_mapping="MX:G4_rising",
            --height=MINISLIDER_HEIGHT,
            width=170,
            min=def.GAUSSIAN_V_MIN,
            max=def.GAUSSIAN_V_MAX,
            value=tmp.GAUSSIAN_V4,
            notifier = function(value)
              tmp.GAUSSIAN_V4 = value
              redraw_sample()
            end
          },
        },
        vb:row{
          vb:text{text="Macuilxochitl rising", width=130},
          vb:slider{
            id="gauss_v5",
            midi_mapping="MX:G5_rising",
            --height=MINISLIDER_HEIGHT,
            width=170,
            min=def.GAUSSIAN_V_MIN,
            max=def.GAUSSIAN_V_MAX,
            value=tmp.GAUSSIAN_V5,
            notifier = function(value)
              tmp.GAUSSIAN_V5 = value
              redraw_sample()
            end
          },
        },
      },
    },
    vb:column{
      id="gods2",
      spacing=DEFAULT_SPACING,
      margin = DEFAULT_MARGIN,
      height = DEFAULT_HEIGHT,
      style="group",
      width=320,
      vb:row{
        vb:text{text="Huehuecóyotl dancing", width=130},
        vb:slider{
          id="gauss_n1",
          midi_mapping="MX:G1_dancing",
          --height=MINISLIDER_HEIGHT,
          width=170,
          min=def.GAUSSIAN_N_MIN,
          max=def.GAUSSIAN_N_MAX,
          value=tmp.GAUSSIAN_N1,
          notifier = function(value)
            tmp.GAUSSIAN_N1 = value
            redraw_sample()
          end
        },
      },
      vb:row{
        vb:text{text="Ah-Xoc-Xin dancing", width=130},
        vb:slider{
          id="gauss_n2",
          midi_mapping="MX:G2_dancing",
          --height=MINISLIDER_HEIGHT,
          width=170,
          min=def.GAUSSIAN_N_MIN,
          max=def.GAUSSIAN_N_MAX,
          value=tmp.GAUSSIAN_N2,
          notifier = function(value)
            tmp.GAUSSIAN_N2 = value
            redraw_sample()
          end
        },
      },
      vb:row{
        vb:text{text="Xochiquetzal dancing", width=130},
        vb:slider{
          id="gauss_n3",
          midi_mapping="MX:G3_dancing",
          --height=MINISLIDER_HEIGHT,
          width=170,
          min=def.GAUSSIAN_N_MIN,
          max=def.GAUSSIAN_N_MAX,
          value=tmp.GAUSSIAN_N3,
          notifier = function(value)
            tmp.GAUSSIAN_N3 = value
            redraw_sample()
          end
        },
      },
      vb:row{
        vb:text{text="Sak Nik dancing", width=130},
        vb:slider{
          id="gauss_n4",
          midi_mapping="MX:G4_dancing",
          --height=MINISLIDER_HEIGHT,
          width=170,
          min=def.GAUSSIAN_N_MIN,
          max=def.GAUSSIAN_N_MAX,
          value=tmp.GAUSSIAN_N4,
          notifier = function(value)
            tmp.GAUSSIAN_N4 = value
            redraw_sample()
          end
        },
      },
      vb:row{
        vb:text{text="Macuilxochitl dancing", width=130},
        vb:slider{
          id="gauss_n5",
          midi_mapping="MX:G5_dancing",
          --height=MINISLIDER_HEIGHT,
          width=170,
          min=def.GAUSSIAN_N_MIN,
          max=def.GAUSSIAN_N_MAX,
          value=tmp.GAUSSIAN_N5,
          notifier = function(value)
            tmp.GAUSSIAN_N5 = value
            redraw_sample()
          end
        },
      },
    },
    vb:column{
      id="gods3",
      spacing=DEFAULT_SPACING,
      margin = DEFAULT_MARGIN,
      height = DEFAULT_HEIGHT,
      style="group",
      width=320,
      vb:row{
        vb:text{text="Huehuecóyotl expands", width=130},
        vb:slider{
          id="gauss_s1",
          midi_mapping="MX:G1_expands",
          --height=MINISLIDER_HEIGHT,
          width=170,
          min=def.GAUSSIAN_S_MIN,
          max=def.GAUSSIAN_S_MAX,
          value=tmp.GAUSSIAN_S1,
          notifier = function(value)
            tmp.GAUSSIAN_S1 = value
            redraw_sample()
          end
        },
      },
      vb:row{
        vb:text{text="Ah-Xoc-Xin expands", width=130},
        vb:slider{
          id="gauss_s2",
          midi_mapping="MX:G2_expands",
          --height=MINISLIDER_HEIGHT,
          width=170,
          min=def.GAUSSIAN_S_MIN,
          max=def.GAUSSIAN_S_MAX,
          value=tmp.GAUSSIAN_S2,
          notifier = function(value)
            tmp.GAUSSIAN_S2 = value
            redraw_sample()
          end
        },
      },
      vb:row{
        vb:text{text="Xochiquetzal expands", width=130},
        vb:slider{
          id="gauss_s3",
          midi_mapping="MX:G3_expands",
          --height=MINISLIDER_HEIGHT,
          width=170,
          min=def.GAUSSIAN_S_MIN,
          max=def.GAUSSIAN_S_MAX,
          value=tmp.GAUSSIAN_S3,
          notifier = function(value)
            tmp.GAUSSIAN_S3 = value
            redraw_sample()
          end
        },
      },
      vb:row{
        vb:text{text="Sak Nik expands", width=130},
        vb:slider{
          id="gauss_s4",
          midi_mapping="MX:G4_expands",
          --height=MINISLIDER_HEIGHT,
          width=170,
          min=def.GAUSSIAN_S_MIN,
          max=def.GAUSSIAN_S_MAX,
          value=tmp.GAUSSIAN_S4,
          notifier = function(value)
            tmp.GAUSSIAN_S4 = value
            redraw_sample()
          end
        },
      },
      vb:row{
        vb:text{text="Macuilxochitl expands", width=130},
        vb:slider{
          id="gauss_s5",
          midi_mapping="MX:G5_expands",
          --height=MINISLIDER_HEIGHT,
          width=170,
          min=def.GAUSSIAN_S_MIN,
          max=def.GAUSSIAN_S_MAX,
          value=tmp.GAUSSIAN_S5,
          notifier = function(value)
            tmp.GAUSSIAN_S5 = value
            redraw_sample()
          end
        },
      },
    },
    vb:column{
      id="Finishers",
      spacing=DEFAULT_SPACING,
      margin = DEFAULT_MARGIN,
      height = DEFAULT_HEIGHT,
      style="group",
      width=320,
      vb:row{
        vb:text{text="Select finisher", width=130},
        vb:popup{
          id="finisher_popup",
          midi_mapping="MX:Finisher_selector",
          width=170,
          items=FINISHERS,
          value = tmp.FINISHER_POPUP,
          notifier = function(finisher)
            tmp.FINISHER_POPUP = finisher
            if finisher == 7 then
              vb.views.finisher_slider.min = 0
              vb.views.finisher_slider.max = 0.5
              vb.views.finisher_box.min = 0
              vb.views.finisher_box.max = 0.5
            else
              vb.views.finisher_slider.min = -1
              vb.views.finisher_slider.max = 1
              vb.views.finisher_box.min = -1
              vb.views.finisher_box.max = 1
            end
            redraw_sample()
          end
        },
      },
      vb:row{
        vb:text{text="Amount", width=130},
        vb:slider{
          id="finisher_slider",
          midi_mapping = "MX:Finisher_amount",
          width=105,
          min=-1,
          max=1,
          steps={0.001, 0.01},
          value=tmp.FINISHER_AMOUNT,
          notifier = function(amount)
            tmp.FINISHER_AMOUNT = amount
            vb.views.finisher_box.value = tmp.FINISHER_AMOUNT
            redraw_sample()
          end
        },
        vb:valuefield{
          id="finisher_box",
          width=50,
          min=-1,
          max=1,
          value=tmp.FINISHER_AMOUNT,
          notifier = function(amount)
            tmp.FINISHER_AMOUNT = amount
            vb.views.finisher_slider.value = tmp.FINISHER_AMOUNT
            redraw_sample()
          end
        },
      },
    },
    vb:column{
      spacing=DEFAULT_SPACING,
      margin = DEFAULT_MARGIN,
      height = DEFAULT_HEIGHT,
      style="group",
      width=320,
      vb:row{
        vb:text{text="Render Flow   ->", width=110},
        vb:popup{
          id="modulation_flow",
          width=190,
          items={"Noise  > Shaper > Filter > Gauss",--
                 "Noise  > Shaper > Gauss  > Filter",--
                 "Noise  > Filter > Shaper > Gauss",--
                 "Noise  > Filter > Gauss  > Shaper",--
                 "Noise  > Gauss  > Shaper > Filter",--
                 "Noise  > Gauss  > Filter > Shaper",--
                 "Shaper > Noise  > Filter > Gauss",--
                 "Shaper > Noise  > Gauss  > Filter",--
                 "Shaper > Filter > Noise  > Gauss",--
                 "Shaper > Filter > Gauss  > Noise",--
                 "Shaper > Gauss  > Noise  > Filter",--
                 "Shaper > Gauss  > Filter > Noise",--
                 "Filter > Noise  > Shaper > Gauss",--
                 "Filter > Noise  > Gauss  > Shaper",--
                 "Filter > Shaper > Noise  > Gauss",--
                 "Filter > Shaper > Gauss  > Noise",--
                 "Filter > Gauss  > Noise  > Shaper",--
                 "Filter > Gauss  > Shaper > Noise",--
                 "Gauss  > Noise  > Shaper > Filter",--
                 "Gauss  > Noise  > Filter > Shaper",--
                 "Gauss  > Shaper > Noise  > Filter",--
                 "Gauss  > Shaper > Filter > Noise",--
                 "Gauss  > Filter > Noise  > Shaper",--
                 "Gauss  > Filter > Shaper > Noise"},--
          value=1,
          notifier = function(flow)
            tmp.MODULATION_FLOW = flow
            redraw_sample()
          end
        },
      },
    },
  }

  --[[------------------------------------------------------------------------
  Patches page                                                               -
  ]]--------------------------------------------------------------------------
  local patches_gui = vb:column{
    spacing=DEFAULT_SPACING,
    margin = DEFAULT_MARGIN,
    height = DEFAULT_HEIGHT,
    width=325,
    style="group",
    uniform=true,
    vb:space{height=50},
    vb:horizontal_aligner{
      mode="center",
      vb:button{
        text="Load patch",
        width=200,
        height=32,
        notifier=function()
          local filename = renoise.app():prompt_for_filename_to_read({"*.mxp"}, "Load Macuilxochitl patch")
          if #filename ~= 0 then
            load_patch_file(filename)
            redraw_sample("new_patch")
            vb.views.switcher.value = 1
            vb.views.page1.visible = true
            vb.views.page2.visible = false
            vb.views.page3.visible = false
            vb.views.page4.visible = false
          end
        end
      },
    },
    vb:space{height=30},
    vb:horizontal_aligner{
      mode="center",
      vb:button{
        width=200,
        height=32,
        text="Save patch",
        notifier=function()
          local filename = renoise.app():prompt_for_filename_to_write("mxp", "Save Macuilxochitl patch")
          if #filename ~= 0 then
            save_patch_file(filename)
            vb.views.switcher.value = 1
            vb.views.page1.visible = true
            vb.views.page2.visible = false
            vb.views.page3.visible = false
            vb.views.page4.visible = false
          end
        end
      },
    },
    vb:space{height=30},
    vb:horizontal_aligner{
      mode="center",
      vb:button{
        color={180, 0, 0},
        width=200,
        height=32,
        text="Reset patch",
        notifier=function()
          local answer = renoise.app():show_prompt("Reset patch question", "Really RESET Patch ?", {"Yes", "No"})
          if answer == "Yes" then
            load_patch_file()
            redraw_sample("new_patch")
            vb.views.switcher.value = 1
            vb.views.page1.visible = true
            vb.views.page2.visible = false
            vb.views.page3.visible = false
            vb.views.page4.visible = false
          end
        end
      },
    },
    vb:space{height=100},
  }

  --[[------------------------------------------------------------------------
  Some little info                                                           -
  ]]--------------------------------------------------------------------------
  local info_page = vb:column{
    spacing=DEFAULT_SPACING,
    margin = DEFAULT_MARGIN,
    height = DEFAULT_HEIGHT,
    style="group",
    width=325,
    vb:horizontal_aligner{
      mode="center",
      vb:bitmap{
        mode="transparent",
        bitmap="gfx/info.bmp",
      },
    },
    vb:horizontal_aligner{
      mode="center",
      vb:vertical_aligner{
        mode="top",
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            font="bold",
            style="strong",
            align="center",
            text="Macuilxochitl v" .. VERSION,
          },
        },
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            --font="bold",
            --style="strong",
            align="center",
            text="created by",
          },
        },
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            --font="bold",
            --style="strong",
            align="center",
            text=AUTHOR,
          },
        },
        vb:space{height=10},
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            font="italic",
            align="center",
            text="Is the Mesoamerican god of music and dance",
          },
        },
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            align="center",
            font="italic",
            text="and an experimental extension for Renoise.",
          },
        },
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            style="strong",
            font="italic",
            align="center",
            text="Please be careful and protect your hearing !",
          },
        },
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            font="italic",
            align="center",
            text="Some of the gods are still quite unstable",
          },
        },
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            font="italic",
            align="center",
            text="because they are trapped in an unstable code.",
          },
        },
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            font="italic",
            align="center",
            text="If you like the extension, use it.",
          },
        },
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            font="italic",
            align="center",
            text="Thanks",
          },
        },
        vb:space{height=30},
      },
    },
  }

  --[[------------------------------------------------------------------------
  Main gui                                                                   -
  ]]--------------------------------------------------------------------------
  local make_gui = vb:column{
    spacing=DEFAULT_SPACING,
    margin=DEFAULT_MARGIN,
    height=DEFAULT_HEIGHT,
    vb:horizontal_aligner{
      mode="center",
      id="switch",
      vb:switch{
        id="switcher",
        width=260,
        height=24,
        items={"Oscils", "Gaussians", "Patches", "About"},
        value = 1,
        notifier = function(page)
          if page == 1 then
            vb.views.page1.visible = true
            vb.views.page2.visible = false
            vb.views.page3.visible = false
            vb.views.page4.visible = false
          elseif page == 2 then
            vb.views.page1.visible = false
            vb.views.page2.visible = true
            vb.views.page3.visible = false
            vb.views.page4.visible = false
          elseif page == 3 then
            vb.views.page1.visible = false
            vb.views.page2.visible = false
            vb.views.page3.visible = true
            vb.views.page4.visible = false
          elseif page == 4 then
            vb.views.page1.visible = false
            vb.views.page2.visible = false
            vb.views.page3.visible = false
            vb.views.page4.visible = true
          end
        end
      },
    },
    vb:column{
      spacing=DEFAULT_SPACING,
      margin = DEFAULT_MARGIN,
      height = DEFAULT_HEIGHT,
      id="page1",
      osc_1_gui,
      osc_2_gui,
      osc_3_gui,
      noisy_gui,
      filter_gui,
      frames_gui,
      operator_gui,
    },
    vb:column{
      id="page2",
      gaussian_gui,
    },
    vb:column{
      id="page4",
      info_page,
    },
    vb:column{
      id="page3",
      patches_gui,
    },
    --vb:bitmap{
    --  id="logo_bitmap",
    --  mode="transparent",
    --  bitmap="gfx/info2.bmp"
    --},
  }

  vb.views.switch.visible=true
  vb.views.page1.visible=true
  vb.views.page2.visible=false
  vb.views.page3.visible=false
  vb.views.page4.visible=false
  vb.views.filter_vowel_row.visible=false
  --vb.views.logo_bitmap.visible=true

  -- in default is simple wave set
  --vb.views.osc1detail.visible = false
  --vb.views.osc2detail.visible = false
  --vb.views.osc3detail.visible = false

  -- sample buffer values
  vb.views.framepopup.value = tmp.SAMPLE_POPUP

  Notifiers:add(rnt.app_idle_observable, app_idle)

  redraw_sample("new_start")
  
  dialog = renoise.app():show_custom_dialog(
    "Macuilxochitl",
    make_gui, key_handler)

end