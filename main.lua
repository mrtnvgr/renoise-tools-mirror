--[[----------------------------------------------------------------------------

  Author : Alexander Stoica
  Creation Date : 07/20/2010
  Last modified : 01/31/2012

----------------------------------------------------------------------------]]--

_AUTO_RELOAD_DEBUG = true

require("Classes/OutputDelay")
require("Classes/Manual")

--[[ locals ]]--------------------------------------------------------------]]--

local rd = renoise.Document
local rt = renoise.tool()

local output_delay = OutputDelay()
local manual = Manual()

--[[ preferences ]]---------------------------------------------------------]]--

local preferences = rd.create("MixerSetTrackDelayInSamples") {}
preferences:add_property("output_delay", output_delay.preferences)
rt.preferences = preferences

--[[ notifiers ]]-----------------------------------------------------------]]--

function app_new_document()
  output_delay.help = {manual, 1}
end

rt.app_new_document_observable:add_notifier(app_new_document)

---------------------------------------------------------------------[[ EOF ]]--
