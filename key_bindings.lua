--------------------------------------------------------------------------------
-- key bindings
--------------------------------------------------------------------------------

-- you can also define keybindings for your script, which will be activated and 
-- mapped by the user just as any other key binding in Renoise.
-- Keybindings can be global (apploied everywhere in the GUI) or can be local 
-- to a specific part of the GUI, liek the Pattern Editor.
--
-- Again, have a look at "Renoise.ScriptingTool.API.txt" in the documentation 
-- folder for a complete reference.



renoise.tool():add_keybinding {
  name = "Pattern Editor:Xrns2XMod:Portamento Up",
    invoke = function(repeated)
      if (not repeated) then -- we ignore soft repeated keys here
        portamento_up()
      end
    end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Xrns2XMod:Portamento Down",
    invoke = function(repeated)
      if (not repeated) then -- we ignore soft repeated keys here
        portamento_down()
      end
    end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Xrns2XMod:Volume Slide Up",
    invoke = function(repeated)
      if (not repeated) then -- we ignore soft repeated keys here
        volume_up()
      end
    end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Xrns2XMod:Volume Slide Down",
    invoke = function(repeated)
      if (not repeated) then -- we ignore soft repeated keys here
        volume_down()
      end
    end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Xrns2XMod:Default Volume",
    invoke = function(repeated)
      if (not repeated) then -- we ignore soft repeated keys here
        default_volume()
      end
    end
}

renoise.tool():add_keybinding {
  name = "Global:Xrns2XMod:Helper",
    invoke = function(repeated)
      if (not repeated) then -- we ignore soft repeated keys here
        init_helper_dialog()
      end
    end
}

renoise.tool():add_keybinding {
  name = "Global:Xrns2XMod:Converter",
    invoke = function(repeated)
      if (not repeated) then -- we ignore soft repeated keys here
        init_converter_dialog()
      end
    end
}
