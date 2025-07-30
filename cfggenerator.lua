---------------------------------------------------------------------------------------------------------
-- ReNoam
-- (c) 2012 Ralf Kibiger | f+d+k (fdk@kibiger.com)
-- Creation Date: 2012-01-01
-- Last modified: 2012-01-17
--
-- CFGGenerator code
---------------------------------------------------------------------------------------------------------


class "CFGGenerator"

-- constructor
function CFGGenerator:__init(grammar)
  self.grammar = grammar
end



--[[
returns a matching rule or nil
]]
local function findRule(symbol, rules)

  local candidateRules = table.create()
  local ret = nil

  for _,rule in pairs(rules) do
    local lhs = rule.lhs
    if (lhs == symbol) then
      candidateRules:insert(rule)
    end
  end

  -- now we have all matching rules (0..2)
  if (#candidateRules == 1) then
    ret = candidateRules[1]
  elseif (#candidateRules > 1) then
    -- more than 1 matching rules, we have to pick one of them
    local rand = math.random(#candidateRules) -- this will generate random numbers [1..#candidateRules]
    ret = candidateRules[rand]
  end

  return ret
end





local function findFirstNonterminal(chain, grammar)

  local symb = nil
  local pos = nil

  for position, symbol in pairs(chain) do

    if grammar.nonterminals[symbol] then
      symb = symbol
      pos = position
      break
    end

  end

  return symb, pos
end




-- The chain is expandable, if there is a nonterminal symbol in it.
-- The set of nonterminals and terminals is in the grammar
local function containsNonterminal(chain, grammar)
  local cont = false

  for _, symbol in pairs(chain) do

    if grammar.nonterminals[symbol] then
      cont = true
      break
    end

  end

  return cont
end

--[[
This function does the whole generation process.
It's a simple top-down left-to-right generator.
]]
function CFGGenerator:generate(start)

  local chain = table.create()
  local abbruch = false

  chain:insert(start) -- an array/list/whatever of strings

  print("------------------------------------")
	print("Generation sequence:")
  print("------------------------------------")

  while not abbruch and containsNonterminal(chain, self.grammar) do

    local str = ""
    for _,symb in pairs(chain) do
      str = str .. symb .. " "
    end
    print(str)
    print("------------------------------------")


    -- get the first nonterminal of the chain (there is one - we know this)
    local first, pos = findFirstNonterminal(chain, self.grammar)

   -- print(first .. " (" .. pos .. ")")

    local applyRule = findRule(first, self.grammar.rules)

    if (applyRule == nil) then
      abbruch = true
    else
      -- apply that rule to the chain:
      -- remove the current symbol

      table.remove(chain, pos)

      -- insert the symbols of the RHS
      local rhs = applyRule.rhs
      local offset = 0
      for _,rs in pairs(rhs) do
        table.insert (chain, pos+offset, rs)
        offset = offset + 1
      end


    end --endif

  end

  local str = ""
  for _,symb in pairs(chain) do
    str = str .. symb .. " "
  end
  print(str)
  print("------------------------------------")


  return chain
end

