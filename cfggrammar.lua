---------------------------------------------------------------------------------------------------------
-- ReNoam
-- (c) 2012 Ralf Kibiger | f+d+k (fdk@kibiger.com)
-- Creation Date: 2012-01-01
-- Last modified: 2012-01-17
--
-- CFGGrammar object
---------------------------------------------------------------------------------------------------------





--[[
Formally, a CFG is a 4-tupel <V,T,R,s>
where
V is a set of nonterminal symbols (aka variables)
T is a set of terminal symbols
R is a set of production rules
s is the start symbol

V and T are disjoint
s is a member of V
R is a finite relation from V to (V join T)*

-----------------------------

In this implementaion for renoise, we restrict the grammar:


a) Terminal symbols are strings with numbers exclusively, while nonterminals
are any string with at least 1 non digit character.

b) No epsilon rules.

-----------------------------

With the given restrictions, the sets V and T may be computed when constructing
the grammar object. This is what we do.
]]


class "CFGGrammar"


-- constructor
function CFGGrammar:__init(rules, start)
  self.rules = rules -- an array of CFGRule objects
  self.start = start
  self.terminals = nil
  self.nonterminals = nil




--[[
TODO:
Do some basic grammar checking:

a)Get rid of unreachable rules:
Remove any rules with a nonterminal on the LHS, if this nonterminal doesn't
occur in any of the rules on the RHS and is not the start symbol.
Note: This won't remove cyclic unreachable rules:
X -> Y Z
Y -> Z X
Z -> X Y



z)
For each nonterminal on the RHS of a rule, there has to be at least one rule
with this nonterminal on the LHS
]]



  self.terminals, self.nonterminals = constructSymbolSets(self.rules)

end




function constructSymbolSets(rules)
--[[
  Any symbol on the LHS of a rule is a nonterminal.
  Any symbol on the RHS which is a valid number is a terminal.
]]

  local terminals = table.create()
  local nonterminals = table.create()


  for _,rule in pairs(rules) do
    local lhs = rule.lhs
    local rhs = rule.rhs


    -- add lhs symbol to nonterminals
    -- this is LUA: as we use our symbols as indeces, multiple occurances are handled without further ado
    nonterminals[lhs] = true


    -- for all rhs symbols, check if it may be converted into a valid number
    -- if number, add to terminals
    -- if no number, add to nonterminals
    for _,rs in pairs(rhs) do
      local n = tonumber(rs)   -- try to convert it to a number
      if n == nil then
        nonterminals[rs] = true
      else
        terminals[rs] = true
      end
    end

  end



--[[
  print "nonterminals"
  for index,_ in pairs(nonterminals) do
    print(index)
  end

  print "terminals"
  for index,_ in pairs(terminals) do
    print(index)
  end
]]


  return terminals, nonterminals

end



function CFGGrammar:show()

	print("Startsymbol: " .. self.start)
	print("Rules:")
	for _,rule in pairs(self.rules) do
		local str = ""

		local lhs = rule.lhs
		local rhs = rule.rhs

		str = lhs .. " ->"

		for _,rs in pairs(rhs) do
			str = str .. " " .. rs
		end
		print(str)
	end

end
