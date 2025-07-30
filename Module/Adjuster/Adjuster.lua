--- ======================================================================================================
---
---                                                 [ Adjuster Module ]
---
--- Adjustment module (copy/paste after editing)

class "Adjuster" (PatternEditorModule)

require 'Module/Adjuster/Bank'
require 'Module/Adjuster/Effects'
require 'Module/Adjuster/Library'
require 'Module/Adjuster/LaunchpadUI'
require 'Module/Adjuster/IdleHooks'

Adjuster.color = {
    column = {
        active   = 1,
        inactive = 10,
    },
    on    = 1,
    off   = 2,
    empty = 0,
    steppor = 100,
}

--- ======================================================================================================
---
---                                                 [ INIT ]

function Adjuster:__init()
    PatternEditorModule:__init(self)
    --
    self.playback_key = 'adjuster'
    --
    self.delay       = 0
    self.volume      = Note.instrument.empty
    self.pan         = Note.instrument.empty
    --
    self.mode        = CopyPasteStore.COPY_MODE
    --
    self.color = {
        stepper = NewColor[0][3],
        map = self:__get_color_map(),
        selected = {
            -- only on is needed
            off   = BlinkColor[0][3],
            on    = BlinkColor[0][3],
            empty = BlinkColor[0][3],
        },
    }
    --
    self:__init_playback_position()
    self:__init_bank()
    self:__init_launchpad_matrix()
    self:__init_effects()
    self:__init_idle()
end


function Adjuster:_activate()
    self:__activate_playback_position()
    self:__activate_bank()
    self:__activate_effects()
    self:__activate_idle()
    -- must be last
    self:__activate_launchpad_matrix()
end

--- tear down
--
function Adjuster:_deactivate()
    self:__deactivate_bank()
    self:__deactivate_playback_position()
    self:__deactivate_effects()
    self:__deactivate_idle()
    -- must be last
    self:__deactivate_launchpad_matrix()
end

function Adjuster:wire_launchpad(pad)
    self.pad = pad
end

function Adjuster:__get_color_map()
    local active_column   = Adjuster.color.column.active
    local inactive_column = Adjuster.color.column.inactive
    local on              = Adjuster.color.on
    local off             = Adjuster.color.off
    local empty           = Adjuster.color.empty
    local steppor         = Adjuster.color.steppor
    --
    local active_column_and_on      = NewColor[3][3]
    local active_column_and_off     = NewColor[3][0]
    local active_column_and_empty   = NewColor[0][0]
    local inactive_column_and_on    = NewColor[1][1]
    local inactive_column_and_off   = NewColor[1][0]
    --
    local active_column_and_on_step      = BlinkColor[0][3]
    local active_column_and_off_step     = BlinkColor[0][3]
    local active_column_and_empty_step   = BlinkColor[0][3]
    local inactive_column_and_on_step    = BlinkColor[0][3]
    local inactive_column_and_off_step   = BlinkColor[0][3]
    --
    -- create map
    --
    local map = {}
    map[ active_column * on    + inactive_column * empty ] = active_column_and_on
    map[ active_column * off   + inactive_column * empty ] = active_column_and_off
    map[ active_column * empty + inactive_column * empty ] = active_column_and_empty
    --
    map[ active_column * on    + inactive_column * on    ] = active_column_and_on
    map[ active_column * off   + inactive_column * on    ] = active_column_and_off
    map[ active_column * empty + inactive_column * on    ] = inactive_column_and_on
    --
    map[ active_column * on    + inactive_column * off   ] = active_column_and_on
    map[ active_column * off   + inactive_column * off   ] = active_column_and_off
    map[ active_column * empty + inactive_column * off   ] = inactive_column_and_off
    --
    map[ active_column * on    + inactive_column * empty + steppor ] = active_column_and_on_step
    map[ active_column * off   + inactive_column * empty + steppor ] = active_column_and_off_step
    map[ active_column * empty + inactive_column * empty + steppor ] = active_column_and_empty_step
    --
    map[ active_column * on    + inactive_column * on    + steppor ] = active_column_and_on_step
    map[ active_column * off   + inactive_column * on    + steppor ] = active_column_and_off_step
    map[ active_column * empty + inactive_column * on    + steppor ] = inactive_column_and_on_step
    --
    map[ active_column * on    + inactive_column * off   + steppor ] = active_column_and_on_step
    map[ active_column * off   + inactive_column * off   + steppor ] = active_column_and_off_step
    map[ active_column * empty + inactive_column * off   + steppor ] = inactive_column_and_off_step
    return map
end
