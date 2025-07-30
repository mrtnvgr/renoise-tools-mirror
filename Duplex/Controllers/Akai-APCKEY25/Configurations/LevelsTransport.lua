--[[----------------------------------------------------------------------------
-- Duplex.Akai-APCKEY25
----------------------------------------------------------------------------]]--

duplex_configurations:insert {
  -- configuration properties
  name = "Levels + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,
    display_name = "Akai-APCKEY25",
    device_port_in = "APC Key 25",
    device_port_out = "APC Key 25",
    control_map = "Controllers/Akai-APCKEY25/Controlmaps/Akai-APCKEY25.xml",
    thumbnail = "Controllers/Akai-APCKEY25/Akai-APCKEY25.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },

  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Encoders_*",
        },
      },
    },
    Transport = {
      mappings = {
        stop_playback = {
          group_name = "Transport",
          index = 1,
        },
        start_playback = {
          group_name = "Transport",
          index = 2,
        },
        edit_mode = {
          group_name = "Transport",
          index = 3,
        },
      },
    },
  }
}

