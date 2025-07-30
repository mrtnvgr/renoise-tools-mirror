---------------------------------------------------------------------------------------------------------
-- ReNoam
-- (c) 2012 Ralf Kibiger | f+d+k (fdk@kibiger.com)
-- Creation Date: 2012-01-01
-- Last modified: 2012-01-17
--
-- CFGRule object
---------------------------------------------------------------------------------------------------------

--[[
  LHS is a string
  RHS is a list of strings
]]

class "CFGRule"

function CFGRule:__init(lhs, rhs)
  self.lhs = lhs
  self.rhs = rhs
end
