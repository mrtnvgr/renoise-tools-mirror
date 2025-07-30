--[[============================================================================
main.lua
============================================================================]]--


-- Reload the script whenever this file is saved.
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function() end

math.randomseed (os.clock ())

require "Shaper"
local shaper = nil
if not shaper then
  shaper = Shaper()
end

--~ require "Modifier"
--~ local modifier = nil
--~ if not modifier then
  --~ modifier = Modifier()
--~ end
