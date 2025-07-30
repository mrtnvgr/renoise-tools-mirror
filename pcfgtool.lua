---------------------------------------------------------------------------------------------------------
-- ReNoam
-- (c) 2012 Ralf Kibiger | f+d+k (fdk@kibiger.com)
-- Creation Date: 2012-01-19
-- Last modified: 2012-01-19
--
-- PCFGTool code
---------------------------------------------------------------------------------------------------------

require "pcfggrammar"
require "pcfgrule"
require "pcfggenerator"


class "PCFGTool"

-- constructor
function PCFGTool:__init()
end

local function parseRulePCFG(gline)
	--line has the following format:
	--LHS -> RHS1 RHS2 ... RHSn
	--or
	--LHS -> RHS1 RHS2 ... RHSn <Probability>

	local prob = nil

	local symbols = table.create()
	for symb in string.gmatch(gline, "[^%s]+") do
		table.insert(symbols, symb)
	end

	--remove the first two symbols from the symbols table
	local lhs = table.remove(symbols,1)
	local arrowdummy = table.remove(symbols,1)

	--check last symbol. if it starts with '<' and ends with '>', it's a probability
	--NOTE: this would be the probability supplied by the user! Those probabilties have to be checked and
	--adjusted if needed.

	local lastsymbol = symbols[#symbols]

	if ((string.sub(lastsymbol,1,1) == "<") and (string.sub(lastsymbol,string.len(lastsymbol),string.len(lastsymbol)) == ">")) then
		-- something like <...>

		local probstring = string.sub(lastsymbol,2,string.len(lastsymbol)-1)

		-- check if probstring is a valid probability
		local n = tonumber(probstring)   -- try to convert it to a number
    if n == nil then
      --whatever is between the angle brackets is no number - keep the symbol
		else
			--a number - so remove lastsymbol from symbols
			table.remove(symbols)
			if (n > 0) then
				--now this is a valid probability supplied by the user!
				prob = n
			else
				-- n <= 0 - ignore it
			end
    end

	else
		--no probability supplied
	end

	return PCFGRule(lhs, symbols, prob)
end


local function parseGrammarTextPCFG(glines)

	--parse the lines
	local validlinescount = 0
  local start = nil
  local rules = table.create()
	local r

  for _,gline in pairs(glines) do
		if (gline ~= "") then
			if (string.sub(gline,1,1) ~= "#") then

				validlinescount = validlinescount + 1

				--grammar line, parse
				if (validlinescount == 1) then
						--grammartype, ignore
				elseif (validlinescount == 2) then
						--start symbol
						start = gline
				else
					--rule
					r = parseRulePCFG(gline)
					rules:insert(r)
				end

			else
				--comment line, ignore
			end
		else
			--empty line, ignore
		end
  end

	return rules, start
end

function PCFGTool:process(glines)
	local chain = nil
	-- parse the string
	local rules, start = parseGrammarTextPCFG(glines)
	--init grammar
	local g = PCFGGrammar(rules, start)
	g:show()
	--	TODO: some basic grammar checking



	local gen = PCFGGenerator(g)
	chain = gen:generate(start)

	return chain
end
