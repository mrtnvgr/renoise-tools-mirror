---------------------------------------------------------------------------------------------------------
-- ReNoam
-- (c) 2012 Ralf Kibiger | f+d+k (fdk@kibiger.com)
-- Creation Date: 2012-01-01
-- Last modified: 2012-01-19
--
-- Main
---------------------------------------------------------------------------------------------------------


_AUTO_RELOAD_DEBUG = true

require "cfgtool"
require "pcfgtool"


TOOL_NAME = "ReNoam"
TOOL_VERSION = "0.8"
TOOL_DATETIME = "2012-01-19 12:51"

vb = nil
dialog = nil

---------------------------------------------------------------------------------------------------------
-- preferences
---------------------------------------------------------------------------------------------------------

local preferences = renoise.Document.create("ReNoamPreferences") {
  grammartext =
        "\n" ..
        "# Hi & welcome to " .. TOOL_NAME .. " " .. TOOL_VERSION .. "\n" ..
        "\n" ..
        "# There is also a short readme.txt, why not have a look?\n" ..
        "\n" ..
        "\n" ..
				"# This text area is where your grammar should go.\n" ..
        "# Lines starting with '#' and empty lines are ignored.\n" ..
        "# Please use them to keep your grammars commented, clean, and tidy.\n" ..
        "#\n" ..
        "# In the first valid line you have to set the grammar type.\n" ..
        "# ReNoam v0.8 supports 'cfg' and 'pcfg'\n" ..
        "# CFG stands for context free grammar\n" ..
        "# PCFG stands for probabilistic context free grammar\n" ..
        "# Please see the manual for this.\n" ..
        "#\n" ..
        "# This example is a CFG:\n" ..
        "ReNoamGrammarType = cfg\n" ..
        "#\n" ..
        "# The next valid line has to contain the start symbol, e.g. 'S' or 'Song' or whatever you like.\n" ..
        "#\n" ..
        "# After the start symbol, the rules are specified.\n" ..
        "# All rules in a CFG have a left hand side symbol (LHS), a right pointing arrow '->', and one or more right hand side symbols (RHS).\n" ..
        "# If a rule is applied by the generator, the LHS is simply replaced by the RHS.\n" ..
        "# If there is more than one rule with a matching LHS, the generator picks one of them randomly.\n" ..
        "# Please see the manual for PCFGs.\n" ..
        "# \n" ..
        "# \n" ..
        "# Note:\n" ..
        "# Symbols are delimited by whitespaces (i.e. tabs/blanks).\n" ..
        "# Valid numbers are terminal symbols. They refer to the appropriate pattern numbers.\n" ..
        "# Any other strings are nonterminal symbols.\n" ..
        "# \n" ..
        "# A short example:\n" ..
        "\n" ..
        "\n" ..
        "#######################\n" ..
        "# Start symbol:\n" ..
        "#######################\n" ..
        "Song\n" ..
        "\n" ..
        "#######################\n" ..
        "# Rules:\n" ..
        "#######################\n" ..
        "Song -> Struct1 End\n" ..
        "Song -> Intro Struct2 End\n" ..
        "Song -> Struct3\n" ..
        "\n" ..
        "Struct1 -> A B C\n" ..
        "Struct2 -> A C A C B A A\n" ..
        "Struct3 -> A B A C A C C\n" ..
        "\n" ..
        "A -> 0 1 2 3\n" ..
        "C -> 4 5 6 7\n" ..
        "B -> 8 9 10 11\n" ..
        "Intro -> 8 4 8 4 12 1 12 1\n" ..
        "End -> 12 13 14 15\n" ..
        "\n" ..
        "\n" ..
        "\n"
}
renoise.tool().preferences = preferences

---------------------------------------------------------------------------------------------------------
--
---------------------------------------------------------------------------------------------------------

local function getGrammarType(glines)

	local grammartype = "cfg"		-- default grammar type is CFG
	local foundinfo = false

	--parse the lines
  for _,gline in pairs(glines) do
		if (gline ~= "") then
			if (string.sub(gline,1,1) ~= "#") then

				--first valid line
				--check if this is a grammar type information line
				if (string.sub(gline,1,17) == "ReNoamGrammarType") then
					--get the grammar type information
					--format is:
					--ReNoamGrammarType = TYPE
					--where TYPE is a grammar type
					local grammarTypeTokens = table.create()
					for symb in string.gmatch(gline, "[^%s]+") do
						table.insert(grammarTypeTokens, symb)
					end
					--remove the first two symbols from the table
					local dummy
					dummy = table.remove(grammarTypeTokens,1) -- keyword ReNoamGrammarType
					dummy = table.remove(grammarTypeTokens,1) -- equals sign
					grammartype = grammarTypeTokens[1]
					foundinfo = true
				end
				break -- don't look further than the first line

			else
				--comment line, ignore
			end
		else
			--empty line, ignore
		end
  end--for

	return grammartype, foundinfo
end


local function makeGrammarGenerateChain(grammartext)

	local chain = nil

	-- split in separate lines
	grammartext = grammartext .. "\n" -- we need at least one \n at the end
	local glines = table.create()
	for w in string.gmatch(grammartext, "([^\n]*)\n") do
		table.insert(glines, w)
	end

--[[
	what precisely has to be done here depends on the grammar type!
	so first thing to do is check the grammar type.
	after that branch
]]
	local grammartype, foundinfo = getGrammarType(glines)

	if (grammartype == "cfg") then
		chain = CFGTool:process(glines, foundinfo)
		--chain = processCFG(glines, foundinfo) -- this is the only grammar type where we use foundinfo
	elseif (grammartype == "pcfg") then
		chain = PCFGTool:process(glines)
		--chain = processPCFG(glines)
	else
		--unknown grammar type
	end

	return chain
end



---------------------------------------------------------------------------------------------------------
-- button actions
---------------------------------------------------------------------------------------------------------

local function actionGenerate()

	-- get the text of the GUI vb:multiline_textfield as one string and process it
	local chain = makeGrammarGenerateChain(vb.views.grammartextfield.text)

	-- append pattern sequence
	local numPatterns = #renoise.song().sequencer.pattern_sequence
	local insertPos = numPatterns
	for _,symb in pairs(chain) do
		renoise.song().sequencer:insert_sequence_at(insertPos+1, tonumber(symb)+1)
		insertPos = insertPos + 1
	end

	--Insert a section header
	renoise.song().sequencer:set_sequence_is_start_of_section(numPatterns+1, true)
	renoise.song().sequencer:set_sequence_section_name(numPatterns+1, "Generated by " .. TOOL_NAME)

end

local function actionSaveGrammar()
	local dialogTitle = "Save grammar"
	local filename = renoise.app():prompt_for_filename_to_write("txt", dialogTitle)
	--print(">>>"..filename.."<<<")
	if (filename ~= "") then
		local fh = io.open(filename, "w")
		fh:write(vb.views.grammartextfield.text)
		fh:close()
	end
end

local function actionLoadGrammar()
	local dialogTitle = "Load grammar"
	local filename = renoise.app():prompt_for_filename_to_read({"*.txt"}, dialogTitle)
	if (filename ~= "") then
		local strbuf = ""
		for line in io.lines(filename) do
			strbuf = strbuf .. line .. "\n"
		end
		vb.views.grammartextfield.text = strbuf
	end
end

local function actionCloseTool()
	preferences.grammartext.value = vb.views.grammartextfield.text
	dialog:close()
end

---------------------------------------------------------------------------------------------------------
-- GUI
---------------------------------------------------------------------------------------------------------

local function gui()

  if (dialog and dialog.visible) then
    dialog:show()
    return
	end

	vb = renoise.ViewBuilder() -- creating a view builder

	-- remove ids first
--	vb.views["grammartextfield"] = nil

  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
	local BUTTON_WIDTH = 2*renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

  local dialog_title = TOOL_NAME .. " " .. TOOL_VERSION

	local grammartext = preferences.grammartext.value





	local ml_textfield = vb:multiline_textfield {
		id = "grammartextfield",
    width = 600,
    height = 600,
    text = grammartext
  }

	local generate_button = vb:button {
    width = BUTTON_WIDTH,
    text = "Generate",
    notifier = function()
      actionGenerate()
    end
  }

	local save_button = vb:button {
    width = BUTTON_WIDTH,
    text = "Save",
    notifier = function()
      actionSaveGrammar()
    end
  }

	local load_button = vb:button {
    width = BUTTON_WIDTH,
    text = "Load",
    notifier = function()
      actionLoadGrammar()
    end
  }

	local close_button = vb:button {
    width = BUTTON_WIDTH,
    text = "Close",
    notifier = function()
			actionCloseTool()
    end
	}




	local buttonrow =
		vb:row {
			generate_button,
			save_button,
			load_button,
			close_button
		}


	local dialogcolumn =
    vb:column {
      style = "group",
      margin = DEFAULT_MARGIN,
			ml_textfield,
			buttonrow
   }



  local dialog_content = vb:column {
    margin = DEFAULT_MARGIN,
		dialogcolumn
  }



	preferences.grammartext.value = vb.views.grammartextfield.text



  dialog = renoise.app():show_custom_dialog(dialog_title, dialog_content)
end




function main()
  math.randomseed(os.time())
  -- Fix for poor OSX/BSD random behavior
  -- @see: http://lua-users.org/lists/lua-l/2007-03/msg00564.html
  local garbage = math.random()
  garbage = math.random()
	gui()
end

---------------------------------------------------------------------------------------------------------
-- Menus & Keys
---------------------------------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:ReNoam...",
  invoke = function() main() end
}
renoise.tool():add_menu_entry {
  name = "Pattern Matrix:Pattern Sequence:ReNoam...",
  invoke = function() main() end
}

renoise.tool():add_keybinding {
  name = "Pattern Matrix:Pattern Sequence:ReNoam...",
  invoke = function() main() end
}
