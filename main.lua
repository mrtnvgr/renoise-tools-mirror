--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------

require "JFTS"

jftsInst = nil

if (not jftsInst) then
  jftsInst = JFTS()
end


if (jftsInst) then
  jftsInst:register_keys()
end

