_AUTO_RELOAD_DEBUG = function()
end

require "autobender"

renoise.tool():add_menu_entry {
    name = "Track Automation:Autobender...",
    invoke = function () Autobender() end
}

renoise.tool():add_keybinding {
    name = "Global:Tools:Autobender...",
    invoke = function () Autobender() end
}
