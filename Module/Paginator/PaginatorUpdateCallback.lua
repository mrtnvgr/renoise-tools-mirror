--- ======================================================================================================
---
---                                                 [ Paginator Update Callbacks ]


--- ------------------------------------------------------------------------------------------------------
---
---                                                 [ Sub-Module Interface ]


function Paginator:__init_update_callback()
    self.update_callbacks = {}
    self:__create_callback_set_pattern()
end

function Paginator:__activate_update_callback()
end
function Paginator:__deactivate_update_callback()
end

--- ------------------------------------------------------------------------------------------------------
---
---                                                 [ Lib ]

function Paginator:register_update_callback(callback)
    table.insert(self.update_callbacks, callback)
end

function Paginator:__create_callback_set_pattern()
    self.callback_set_pattern = function (index)
        self.pattern_idx = index
    end
end

--- get the active pattern object
--
-- self.pattern_idx will be kept up to date by an observable notifier
--
function Paginator:_active_pattern()
    return renoise.song().patterns[self.pattern_idx]
end

function Paginator:_update_listeners()
    local page = {
        page       = self.page,
        page_start = self.page_start,
        page_end   = self.page_end,
        zoom       = self.zoom,
    }
    for _, callback in ipairs(self.update_callbacks) do
        callback(page)
    end
end
