--[[----------------------------------------------------------------------------

  Author : Alexander Stoica
  Creation Date : 04/10/2011
  Last modified : 12/12/2011

----------------------------------------------------------------------------]]--

_AUTO_RELOAD_DEBUG = true

require("Classes/RateDialog")
require("Classes/Manual")

--[[ locals ]]--------------------------------------------------------------]]--

local rt = renoise.tool()
local rate_dialog = RateDialog()
local manual = Manual()

--[[ notifiers ]]-----------------------------------------------------------]]--

function app_new_document()
  rate_dialog.help = {manual, 1}
  rate_dialog:install()
end

function app_release_document()
  rate_dialog:uninstall()
end

rt.app_new_document_observable:add_notifier(app_new_document)
rt.app_release_document_observable:add_notifier(app_release_document)

---------------------------------------------------------------------[[ EOF ]]--
