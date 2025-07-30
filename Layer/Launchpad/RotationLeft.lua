function Launchpad:_left_callback(msg)
    local result = _is_matrix_left(msg)
    if (result.flag) then
        for _, callback in pairs(self._matrix_listener) do
            callback(self, result)
        end
        return
    end
    --
    result = _is_top_left(msg)
    if (result.flag) then
        for _, callback in pairs(self._top_listener) do
            callback(self, result)
        end
        return
    end
    --
    result = _is_side_left(msg)
    if (result.flag) then
        for _, callback in pairs(self._side_listener) do
            callback(self, result)
        end
        return
    end
end

--- Test functions for the handler
--

function _is_side_left(msg)
    if msg[1] == 0xB0 then
        local x = msg[2] - 0x68
        if (x > -1 and x < 8) then
            return { flag = true,  x = (8 - x), vel = msg[3] }
        end
    end
    return LaunchpadData.no
end
function _is_top_left(msg)
    if msg[1] == 0x90 then
        local note = msg[2]
        if (bit.band(0x08,note) == 0x08) then
            local x = bit.rshift(note,4)
            if (x > -1 and x < 8) then
                return { flag = true,  x = (x + 1), vel = msg[3] }
            end
        end
    end
    return LaunchpadData.no
end
function _is_matrix_left(msg)
    if msg[1] == 0x90 then
        local note = msg[2]
        if (bit.band(0x08,note) == 0) then
            local y = bit.rshift(note,4)
            local x = bit.band(0x07,note)
            if ( x > -1 and x < 8 and y > -1  and y < 8 ) then
                return { flag = true , y = 8 - x , x = (y + 1), vel = msg[3] }
            end
        end
    end
    return LaunchpadData.no
end



---
-- Set parameters

function Launchpad:_set_matrix_left( a, b , color )
    local y = a - 1
    local x = 8 - b
    if ( x < 8 and x > -1 and y < 8 and y > -1) then
        self:send(0x90 , y * 16 + x , color)
    end
end

function Launchpad:_set_side_left(a,color)
    local x = 8 - a
    if ( x > -1 and x < 8 ) then
        self:send( 0xB0, x + 0x68, color)
    end
end

function Launchpad:_set_top_left(a,color)
    local x = a - 1
    if ( x > -1 and x < 8 ) then
        self:send( 0x90, 0x10 * x + 0x08, color)
    end
end
