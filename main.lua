_AUTO_RELOAD_DEBUG = true

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Clear",
  invoke = function()
    renoise.song().selection_in_pattern = {}
  end
}

renoise.tool():add_keybinding {
  name = "Phrase Editor:Selection:Clear",
  invoke = function()
    renoise.song().selection_in_phrase = {}
  end
}


