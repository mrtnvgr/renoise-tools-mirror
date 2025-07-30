---@diagnostic disable: undefined-global, lowercase-global
--------------------------------------------------------------------------------------------------------
-- GUI DEFINITION                                                                                      -
--------------------------------------------------------------------------------------------------------

ACTIVE_GUI_PAGE = 1
TEXT_WIDTH = 60
SLIDER_WIDTH = 120
VALUE_WIDTH = 60
POPUP_WIDTH = 180
BUTTON_WIDTH = 240

SAMPLERATE = {"11025", "22050", "44100", "48000", "96000", "192000"}
BITS = {"8", "16", "24", "32"}
CHORDS = {"---", "Dur", "Maj", "Min"}

page_1 = vb:vertical_aligner{
  mode="top",
  id="page_1",
  spacing=renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
  vb:column{
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
    style="group",
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Note"},
      vb:popup{
        id="selected_note",
        width=90,
        items=NOTES,
        value=settings.selected_note,
        notifier=function(note)
          settings.selected_note = note
            string_draw()
        end
      },
      vb:popup{
        id="selected_octave",
        width=90,
        items={"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"},
        value=settings.selected_octave,
        notifier=function(octave)
          settings.selected_octave = octave - 1
          string_draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Crop:"},
      vb:slider{width=SLIDER_WIDTH,
        id="crop_slider",
        min=0.0,
        max=5.0,
        value=settings.crop,
        steps={0.01, 0.1},
        notifier=function(crop)
          settings.crop = crop
          vbs.crop_box.value=crop
          string_draw()
        end
      },
      vb:valuefield{width=VALUE_WIDTH,
        id="crop_box",
        min=0.0,
        max=5.0,
        value=settings.crop,
        notifier=function(crop)
          settings.crop=crop
          vbs.crop_slider.value=crop
          string_draw()
        end
      },
    },
  },
  vb:column{
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
    style="group",
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Source"},
      vb:popup{
        id="noise_source",
        width=POPUP_WIDTH,
        items={"White noise", "Pink noise", "Brownian noise"},
        value=settings.noise_source,
        notifier=function(source)
          settings.noise_source = source
          string_draw()
        end 
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Filter"},
      vb:popup{
        id="filter",
        width=POPUP_WIDTH,
        items={"Lowpass", "Highpass", "Bandpass",
               "Notch", "Allpass", "PeakEQ", "Lowshelf", "Highshelf", "None"},
        value=settings.filter,
        notifier=function(filter)
          settings.filter = filter
          if filter == 9 then
            vbs.filter_frequency_slider.active=false
            vbs.filter_frequency_box.active=false
            vbs.filter_quality_slider.active=false
            vbs.filter_quality_box.active=false
            vbs.filter_gain_slider.active=false
            vbs.filter_gain_box.active=false
            vbs.filter_wet_slider.active=false
            vbs.filter_wet_box.active=false
          else
            vbs.filter_frequency_slider.active=true
            vbs.filter_frequency_box.active=true
            vbs.filter_quality_slider.active=true
            vbs.filter_quality_box.active=true
            vbs.filter_gain_slider.active=true
            vbs.filter_gain_box.active=true
            vbs.filter_wet_slider.active=true
            vbs.filter_wet_box.active=true
          end
          string_draw()
        end 
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Frequency"},
      vb:slider{width=SLIDER_WIDTH,
        id="filter_frequency_slider",
        min=20.0,
        max=20000.0,
        value=settings.filter_frequency,
        steps={0.1, 1},
        notifier=function(ffreq)
          settings.filter_frequency = ffreq
          vbs.filter_frequency_box.value = ffreq
          if settings.filter < 9 then
            string_draw()
          end
        end
      },
      vb:valuefield{width=VALUE_WIDTH,
        id="filter_frequency_box",
        min=20.0,
        max=20000.0,
        value=settings.filter_frequency,
        notifier=function(ffreq)
          settings.filter_frequency=ffreq
          vbs.filter_frequency_slider.value=ffreq
          if settings.filter < 9 then
            string_draw()
          end
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Quality"},
      vb:slider{width=SLIDER_WIDTH,
        id="filter_quality_slider",
        min=1,
        max=20,
        value=settings.filter_quality,
        steps={0.1, 1},
        notifier=function(qual)
          settings.filter_quality = qual
          vbs.filter_quality_box.value=qual
          if settings.filter < 9 then
            string_draw()
          end
        end
      },
      vb:valuefield{width=VALUE_WIDTH,
        id="filter_quality_box",
        min=1,
        max=20,
        value=settings.filter_quality,
        notifier=function(qual)
          settings.filter_quality=qual
          vbs.filter_quality_slider.value=qual
          if settings.filter < 9 then
            string_draw()
          end
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Gain"},
      vb:slider{width=SLIDER_WIDTH,
        id="filter_gain_slider",
        min=1.0,
        max=5.0,
        value=settings.filter_gain,
        steps={0.1, 1},
        notifier=function(gain)
          settings.filter_gain = gain
          vbs.filter_gain_box.value=gain
          if settings.filter < 9 then
            string_draw()
          end
        end
      },
      vb:valuefield{width=VALUE_WIDTH,
        id="filter_gain_box",
        min=1.0,
        max=5.0,
        value=settings.filter_gain,
        notifier=function(gain)
          settings.filter_gain=gain
          vbs.filter_gain_slider.value=gain
          if settings.filter < 9 then
            string_draw()
          end
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Dry / Wet"},
      vb:slider{width=SLIDER_WIDTH,
        id="filter_wet_slider",
        min=0.0,
        max=1.0,
        value=settings.filter_wet,
        steps={0.01, 0.1},
        notifier=function(wet)
          settings.filter_wet = wet
          vbs.filter_wet_box.value=wet
          if settings.filter < 9 then
            string_draw()
          end
        end
      },
      vb:valuefield{width=VALUE_WIDTH,
        id="filter_wet_box",
        min=0.0,
        max=1.0,
        value=settings.filter_wet,
        notifier=function(wet)
          settings.filter_wet=wet
          vbs.filter_wet_slider.value=wet
          if settings.filter < 9 then
            string_draw()
          end
        end
      },
    },
  },
  vb:column{
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
    style="group",
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Damp fltr"},
      vb:horizontal_aligner{
        mode="center",
        vb:switch{
          width=POPUP_WIDTH,
          height=24,
          id="damping_filter",
          items={"One zero", "Two zero", "Both"},
          value=settings.damping_filter,
          notifier=function(df)
            settings.damping_filter = df
            string_draw()
          end
        },
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="RC"},
      vb:slider{
        id="RC_f_slider",
        width=SLIDER_WIDTH,
        min=1,
        max=16,
        value=settings.RC_f0,
        steps={1, 1},
        notifier = function(f0)
          settings.RC_f0 = f0
          vbs.RC_f_box.value=f0
          string_draw()
        end
      },
      vb:valuefield{width=VALUE_WIDTH,
        id="RC_f_box",
        min=1,
        max=16,
        value=settings.RC_f0,
        notifier=function(f0)
          settings.RC_f0=f0
          vbs.RC_f_slider.value=f0
          string_draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="RC time"},
      vb:slider{
        id="RC_dt_slider",
        width=SLIDER_WIDTH,
        min=0.0001,
        max=1.0,
        value=settings.RC_dt,
        steps={0.0001, 0.01},
        notifier = function(dt)
          settings.RC_dt = dt
          vbs.RC_dt_box.value=dt
          string_draw()
        end
      },
      vb:valuefield{width=VALUE_WIDTH,
        id="RC_dt_box",
        min=0.0001,
        max=1.0,
        value=settings.RC_dt,
        notifier=function(dt)
          settings.RC_dt=dt
          vbs.RC_dt_slider.value=dt
          string_draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Position"},
      vb:slider{
        id="beta_slider",
        width=SLIDER_WIDTH,
        min=0.0,
        max=10.0,
        value=settings.beta,
        steps={0.01, 0.1},
        notifier = function(beta)
          settings.beta = beta
          vbs.beta_box.value=beta
          string_draw()
        end
      },
      vb:valuefield{width=VALUE_WIDTH,
        id="beta_box",
        min=0.0,
        max=10.0,
        value=settings.beta,
        notifier=function(beta)
          settings.beta=beta
          vbs.beta_slider.value=beta
          string_draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Decay"},
      vb:slider{
        id="t60_slider",
        width=SLIDER_WIDTH,
        min=0.0,
        max=20.0,
        value=settings.t60,
        steps={0.01, 0.1},
        notifier = function(t60)
          settings.t60 = t60
          vbs.t60_box.value=t60
          string_draw()
        end
      },
      vb:valuefield{width=VALUE_WIDTH,
        id="t60_box",
        min=0.0,
        max=20.0,
        value=settings.t60,
        notifier=function(t60)
          settings.t60=t60
          vbs.t60_slider.value=t60
          string_draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Brightness"},
      vb:slider{
        id="b_slider",
        width=SLIDER_WIDTH,
        min=0.0,
        max=1.0,
        value=settings.B,
        steps={0.01, 0.1},
        notifier = function(B)
          settings.B = B
          vbs.b_box.value=B
          string_draw()
        end
      },
      vb:valuefield{width=VALUE_WIDTH,
        id="b_box",
        min=0.0,
        max=1.0,
        value=settings.B,
        notifier=function(B)
          settings.B=B
          vbs.b_slider.value=B
          string_draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Mute"},
      vb:slider{
        id="p_slider",
        width=120,
        min=0.0,
        max=0.9,
        value=settings.p,
        steps={0.9, 0.9},
        notifier = function(p)
          settings.p = p
          vbs.p_box.value=p
          string_draw()
        end
      },
      vb:valuefield{width=VALUE_WIDTH,
        id="p_box",
        min=0.0,
        max=0.9,
        value=settings.p,
        notifier=function(p)
          settings.p=p
          vbs.p_slider.value=p
          string_draw()
        end
      },
    },
  },
  vb:column{
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
    style="group",
    vb:horizontal_aligner{
      mode="center",
      vb:button{
        width=BUTTON_WIDTH,
        height=24,
        text="Generate sample",
        notifier=function()
          if settings.render == 1 then
            draw()
          end
        end
      },
    },
  },
}

--[[---------------------------------------------------------------------------------------------------------------------
CHORDS
]]-----------------------------------------------------------------------------------------------------------------------
page_2 = vb:vertical_aligner{
  mode="top",
  id="page_2",
  spacing=renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
  vb:column{
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
    style="group",
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Note 1"},
      vb:popup{
        id="chnote_1",
        width=90,
        items=NOTES,
        value=settings.chnote_1,
        notifier=function(note)
          settings.chnote_1 = note
          --draw()
        end
      },
      vb:popup{
        id="chnote_1_oct",
        width=70,
        items={"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"},
        value=settings.chnote_1_oct,
        notifier=function(octave)
          settings.chnote_1_oct = octave - 1
        end
      },
      vb:checkbox{
        id="chnote_1_on",
        width=18,
        height=18,
        value=settings.chnote_1_on,
        notifier=function(bool)
          settings.chnote_1_on=bool
          --draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Note 2"},
      vb:popup{
        id="chnote_2",
        width=90,
        items=NOTES,
        value=settings.chnote_2,
        notifier=function(note)
          settings.chnote_2 = note
          --draw()
        end
      },
      vb:popup{
        id="chnote_2_oct",
        width=70,
        items={"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"},
        value=settings.chnote_2_oct,
        notifier=function(octave)
          settings.chnote_2_oct = octave-1
          --draw()
        end
      },
      vb:checkbox{
        id="chnote_2_on",
        width=18,
        height=18,
        value=settings.chnote_2_on,
        notifier=function(bool)
          settings.chnote_2_on=bool
          --draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Note 3"},
      vb:popup{
        id="chnote_3",
        width=90,
        items=NOTES,
        value=settings.chnote_3,
        notifier=function(note)
          settings.chnote_3 = note
          --draw()
        end
      },
      vb:popup{
        id="chnote_3_oct",
        width=70,
        items={"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"},
        value=settings.chnote_3_oct,
        notifier=function(octave)
          settings.chnote_3_oct = octave-1
          --draw()
        end
      },
      vb:checkbox{
        id="chnote_3_on",
        width=18,
        height=18,
        value=settings.chnote_3_on,
        notifier=function(bool)
          settings.chnote_3_on=bool
          --draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Note 4"},
      vb:popup{
        id="chnote_4",
        width=90,
        items=NOTES,
        value=settings.chnote_4,
        notifier=function(note)
          settings.chnote_4 = note
          --draw()
        end
      },
      vb:popup{
        id="chnote_4_oct",
        width=70,
        items={"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"},
        value=settings.chnote_4_oct,
        notifier=function(octave)
          settings.chnote_4_oct = octave-1
          --draw()
        end
      },
      vb:checkbox{
        id="chnote_4_on",
        width=18,
        height=18,
        value=settings.chnote_4_on,
        notifier=function(bool)
          settings.chnote_4_on=bool
          --draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Note 5"},
      vb:popup{
        id="chnote_5",
        width=90,
        items=NOTES,
        value=settings.chnote_5,
        notifier=function(note)
          settings.chnote_5 = note
          --draw()
        end
      },
      vb:popup{
        id="chnote_5_oct",
        width=70,
        items={"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"},
        value=settings.chnote_5_oct,
        notifier=function(octave)
          settings.chnote_5_oct = octave-1
          --draw()
        end
      },
      vb:checkbox{
        id="chnote_5_on",
        width=18,
        height=18,
        value=settings.chnote_5_on,
        notifier=function(bool)
          settings.chnote_5_on=bool
          --draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Note 6"},
      vb:popup{
        id="chnote_6",
        width=90,
        items=NOTES,
        value=settings.chnote_6,
        notifier=function(note)
          settings.chnote_6 = note
          --draw()
        end
      },
      vb:popup{
        id="chnote_6_oct",
        width=70,
        items={"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"},
        value=settings.chnote_6_oct,
        notifier=function(octave)
          settings.chnote_6_oct = octave-1
          --draw()
        end
      },
      vb:checkbox{
        id="chnote_6_on",
        width=18,
        height=18,
        value=settings.chnote_6_on,
        notifier=function(bool)
          settings.chnote_6_on=bool
          --draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Note 7"},
      vb:popup{
        id="chnote_7",
        width=90,
        items=NOTES,
        value=settings.chnote_7,
        notifier=function(note)
          settings.chnote_7 = note
          --draw()
        end
      },
      vb:popup{
        id="chnote_7_oct",
        width=70,
        items={"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"},
        value=settings.chnote_7_oct,
        notifier=function(octave)
          settings.chnote_7_oct = octave-1
          --draw()
        end
      },
      vb:checkbox{
        id="chnote_7_on",
        width=18,
        height=18,
        value=settings.chnote_7_on,
        notifier=function(bool)
          settings.chnote_7_on=bool
          --draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Note 8"},
      vb:popup{
        id="chnote_8",
        width=90,
        items=NOTES,
        value=settings.chnote_8,
        notifier=function(note)
          settings.chnote_8 = note
          --draw()
        end
      },
      vb:popup{
        id="chnote_8_oct",
        width=70,
        items={"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"},
        value=settings.chnote_8_oct,
        notifier=function(octave)
          settings.chnote_8_oct = octave-1
          --draw()
        end
      },
      vb:checkbox{
        id="chnote_8_on",
        width=18,
        height=18,
        value=settings.chnote_8_on,
        notifier=function(bool)
          settings.chnote_8_on=bool
          --draw()
        end
      },
    },
  },
  vb:column{
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
    style="group",
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Stroke:"},
      vb:popup{
        id="stroke",
        width=POPUP_WIDTH,
        items={"Down", "Up", "Down/Up", "Up/Down"},
        value=settings.stroke,
        notifier=function(stroke)
          settings.stroke=stroke
        end
      },
    },
    vb:row{
      vb:text{width=160, text="Delay between strings:"},
      vb:valuebox{
        id="string_delay",
        width=80,
        min=0,
        max=2000,
        steps={1, 5},
        value=settings.string_delay,
        notifier=function(delay)
          settings.string_delay=delay
          --draw()
        end
      },
    },
  },
  vb:column{
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
    style="group",
    vb:horizontal_aligner{
      mode="center",
      vb:button{
        width=BUTTON_WIDTH,
        height=24,
        text="Generate sample",
        notifier=function()
          if settings.render == 2 then
            draw()
          end
        end
      },
    },
  },
}

--[[---------------------------------------------------------------------------------------------------------------------------
SETTINGS
]]-----------------------------------------------------------------------------------------------------------------------------
page_3 = vb:vertical_aligner{
  mode="top",
  id="page_3",
  spacing=renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
  vb:column{
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
    style="group",
    vb:space{height=10},
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Smplrate:"},
      vb:popup{width=POPUP_WIDTH,
        id="samplerate",
        items=SAMPLERATE,
        value=settings.samplerate,
        notifier=function(samplerate)
          settings.samplerate = samplerate
          string_draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Bits:"},
      vb:popup{width=POPUP_WIDTH,
        id="bits",
        items=BITS,
        value=settings.bits,
        notifier=function(bits)
          settings.bits = bits
          string_draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Gauss rnd:"},
      vb:popup{width=POPUP_WIDTH,
        id="gauss_rnd",
        items={"1", "2", "3", "4", "5", "6", "7", "8", "9"},
        value=settings.gauss_rnd,
        notifier=function(rnd)
          settings.gauss = rnd
          string_draw()
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Render:"},
      vb:popup{width=POPUP_WIDTH,
        id="render",
        items={"Notes", "Chords"},
        value=settings.render,
        notifier=function(render)
          settings.render = render
        end
      },
    },
    vb:row{
      vb:text{width=TEXT_WIDTH, text="Tunning"},
      vb:popup{width=POPUP_WIDTH,
        id="tunning",
        items={"A = 440Hz", "A = 432 Hz"},
        value=settings.tunning,
        notifier=function(tunning)
          settings.tunning = tunning
        end
      },
    },
  },
  vb:column{
    width=248,
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
    style="group",
    vb:row{
      vb:text{
        text="Sample autorender (No Chords)",
      },
      vb:horizontal_aligner{
        mode="right",
        width=78,
        vb:checkbox{
          id="sample_autorender",
          height=18,
          width=18,
          notifier=function(bool)
            settings.sample_autorender=bool
            draw()
          end
        },
      },
    },
    vb:row{
      vb:text{
        text="Revert sample",
      },
      vb:horizontal_aligner{
        mode="right",
        width=164,
        vb:checkbox{
          id="sample_revert",
          height=18,
          width=18,
          notifier=function(bool)
            settings.sample_revert=bool
            draw()
          end
        },
      },
    },
    vb:row{
      vb:text{
        text="Sample loop",
      },
      vb:horizontal_aligner{
        mode="right",
        width=175,
        vb:popup{
          id="sample_loop",
          width=100,
          items={"NoLoop", "Forward", "Backward", "PingPong"},
          value=settings.sample_loop,
          notifier=function(loop)
            settings.sample_loop=loop
          end
        },
      },
    },
  },
  vb:column{
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
    style="group",
    vb:row{
      vb:button{
        text="Load settings",
        width=BUTTON_WIDTH,
        height=24,
        notifier=function()
          local filename = renoise.app():prompt_for_filename_to_read({"*.rzn"}, "Select patch to load")
          if filename ~= "" then
            local result = Document:load_from(filename)
            if result == nil then
              renoise.app():show_error("Can't load Rezonator patch !!!")
            else
              fill_settings_and_gui()
            end
          end
        end
      },
    },
    vb:space{height=5},
    vb:row{
      vb:button{
        text="Save settings",
        width=BUTTON_WIDTH,
        height=24,
        notifier=function()
          local filename = renoise.app():prompt_for_filename_to_write(".rzn", "Select file to save.")
          if filename ~="" then
            fill_document()
            local result = Document:save_as(filename)
            if result == nil then
              renoise.app():show_error("Can't save Rezonator patch !!!")
            end
          end
        end
      },
    },
  },
}


page_4 = vb:column{
  id="page_4",
  margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
  spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
  height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
  style="group", 
  vb:horizontal_aligner{
    mode="center",
    spacing=renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    vb:bitmap{
      mode="transparent",
      bitmap="logo.bmp",
    },
  },
  vb:horizontal_aligner{
    mode="center",
    vb:text{text="R3z0n4t0r v"..VERSION, font="bold", style="strong"},
  },
  vb:horizontal_aligner{
    mode="center",
    vb:text{text="String instrument by martblek"},
  },
  vb:horizontal_aligner{
    mode="center",
    vb:text{text="based on the work of Karplus-Strong."},
  },
  vb:horizontal_aligner{
    mode="center",
    vb:text{text="If you want"},
  },
  vb:horizontal_aligner{
    mode="center",
    vb:text{text="and your income is over a million"},
  },
  vb:space{height=5},
  vb:horizontal_aligner{
    mode="center",
    vb:button{
      text="buy me a beer",
      width=BUTTON_WIDTH,
      height=24,
      notifier=function()
        renoise.app():open_url("https://paypal.me/martblek")
      end
    },
  },
}

function prepare_for_start()
  if (dialog and dialog.visible) then
    dialog:show()
    return
  end
  vbs.page_1.visible=true
  vbs.page_2.visible=false
  vbs.page_3.visible=false
  vbs.page_4.visible=false
  show_gui()
  fill_settings_and_gui()
end

function show_gui()
  dialog = renoise.app():show_custom_dialog("R3z0n4t0r: Hack the strings",
    vb:column{
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
      vb:column{
        vb:switch{
          width=TEXT_WIDTH + 128 + VALUE_WIDTH,
          height=24,
          items={"Notes", "Chords", "Settings", "Info"},
          value=ACTIVE_GUI_PAGE,
          notifier=function(page)
            if page == 1 then
              vbs.page_1.visible=true
              vbs.page_2.visible=false
              vbs.page_3.visible=false
              vbs.page_4.visible=false
            elseif page == 2 then
              vbs.page_1.visible=false
              vbs.page_2.visible=true
              vbs.page_3.visible=false
              vbs.page_4.visible=false
            elseif page == 3 then
              vbs.page_1.visible=false
              vbs.page_2.visible=false
              vbs.page_3.visible=true
              vbs.page_4.visible=false
            elseif page == 4 then
              vbs.page_1.visible=false
              vbs.page_2.visible=false
              vbs.page_3.visible=false
              vbs.page_4.visible=true
            else
              --
            end

          end
        },
        vb:space{height=2},
        page_1,
        page_2,
        page_3,
        page_4,
      },
    }
  )
end