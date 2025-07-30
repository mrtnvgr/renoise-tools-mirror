


--- ======================================================================================================
---
---                                                 [ Editor Selected Note Sub Module ]


--- ------------------------------------------------------------------------------------------------------
---
---                                                 [ Sub-Module Interface ]


function Editor:__init_selected_note()
    self.note        = Note.note.c
    self.octave      = 4
    -- callbacks
    self:__create_callback_set_note()
end
function Editor:__activate_selected_note()
end
function Editor:__deactivate_selected_note()
end

--- ------------------------------------------------------------------------------------------------------
---
---                                                 [ Lib ]

function Editor:__create_callback_set_note()
    self.callback_set_note =  function (note,octave)
        self.note   = note
        self.octave = octave
    end
end

