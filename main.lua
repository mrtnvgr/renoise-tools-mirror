--[[----------------------------------------------------------------------------

  Author : Alexander Stoica
  Creation Date : 09/10/2011
  Last modified : 09/10/2011

----------------------------------------------------------------------------]]--

_AUTO_RELOAD_DEBUG = true

require("Classes/CopyAutomation")
require("Classes/Manual")

--[[ locals ]]--------------------------------------------------------------]]--

local rt = renoise.tool()

--[[ notifiers ]]-----------------------------------------------------------]]--

function app_new_document()

  local copy_automation = CopyAutomation()
  local manual = Manual()

end

rt.app_new_document_observable:add_notifier(app_new_document)

---------------------------------------------------------------------[[ EOF ]]--
