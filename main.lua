local create_gui = require 'gui'

renoise.tool():add_menu_entry {
	name = 'Main Menu:Tools:Partial Quantize...',
	invoke = function() create_gui(true, 'all_tracks') end,
}

renoise.tool():add_menu_entry {
	name = 'Pattern Editor:Pattern:Partial Quantize...',
	invoke = function() create_gui(false, 'all_tracks') end,
}

renoise.tool():add_menu_entry {
	name = 'Pattern Editor:Track:Partial Quantize...',
	invoke = function() create_gui(false, 'track') end,
}

renoise.tool():add_menu_entry {
	name = 'Pattern Editor:Column:Partial Quantize...',
	invoke = function() create_gui(false, 'column') end,
}

renoise.tool():add_menu_entry {
	name = 'Pattern Editor:Selection:Partial Quantize...',
	invoke = function() create_gui(false, 'selection') end,
}

renoise.tool():add_keybinding {
	name = 'Pattern Editor:Selection:Partially Quantize Selection',
	invoke = function(repeated)
		if not repeated then
			create_gui(false, 'selection')
		end
	end,
}

renoise.tool():add_keybinding {
	name = 'Pattern Editor:Column Operations:Partially Quantize Column',
	invoke = function(repeated)
		if not repeated then
			create_gui(false, 'column')
		end
	end,
}

renoise.tool():add_keybinding {
	name = 'Pattern Editor:Track Operations:Partially Quantize Track',
	invoke = function(repeated)
		if not repeated then
			create_gui(false, 'track')
		end
	end,
}

renoise.tool():add_keybinding {
	name = 'Pattern Editor:Pattern Operations:Partially Quantize Pattern',
	invoke = function(repeated)
		if not repeated then
			create_gui(false, 'all_tracks')
		end
	end,
}