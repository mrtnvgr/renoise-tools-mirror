---------------------------------------------------------------------------------------------------------
-- ReNoam
-- (c) 2012 Ralf Kibiger | f+d+k (fdk@kibiger.com)
-- Creation Date: 2012-01-18
-- Last modified: 2012-01-18
--
-- PCFGRule object
---------------------------------------------------------------------------------------------------------

--[[
  LHS is a string
  RHS is a list of strings
	Prob is a number > 0 (or nil)
]]

class "PCFGRule"

function PCFGRule:__init(lhs, rhs, prob)
  self.lhs = lhs
  self.rhs = rhs
	self.prob = prob
end
