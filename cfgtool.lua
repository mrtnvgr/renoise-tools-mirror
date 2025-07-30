---------------------------------------------------------------------------------------------------------
-- ReNoam
-- (c) 2012 Ralf Kibiger | f+d+k (fdk@kibiger.com)
-- Creation Date: 2012-01-19
-- Last modified: 2012-01-19
--
-- CFGTool code
---------------------------------------------------------------------------------------------------------

require "cfggrammar"
require "cfgrule"
require "cfggenerator"

class "CFGTool"

-- constructor
function CFGTool:__init()
end


local function parseRuleCFG(gline)
	-- line has the following format:
	-- LHS -> RHS1 RHS2 ... RHSn
	local symbols = table.create()
	for symb in string.gmatch(gline, "[^%s]+") do
		table.insert(symbols, symb)
	end

	--remove the first two symbols from the symbols table
	local lhs = table.remove(symbols,1)
	local arrowdummy = table.remove(symbols,1)

	return CFGRule(lhs, symbols)
end


local function parseGrammarTextCFG(glines, foundinfo)

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
					if (foundinfo) then
						--grammartype, ignore
					else
						--start symbol
						start = gline
					end
				elseif (validlinescount == 2) then
					if (foundinfo) then
						--start symbol
						start = gline
					else
						--rule
						r = parseRuleCFG(gline)
						rules:insert(r)
					end
				else
					--rule
					r = parseRuleCFG(gline)
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


function CFGTool:process(glines, foundinfo)
	local chain = nil
	-- parse the string
	local rules, start = parseGrammarTextCFG(glines, foundinfo)
	--init grammar
	local g = CFGGrammar(rules, start)
	g:show()

	--	TODO: some basic grammar checking
	local gen = CFGGenerator(g)
	chain = gen:generate(start)

	return chain
end
