--------------------------------------------------------------------------------
-- Lib Configurator
-- by J. Raben a.k.a. ffx
-- v1.0
--
-- Handles configuration
--------------------------------------------------------------------------------

json = require ('lib/json')


--------------------------------------------------------------------------------

class "LibConfigurator"

LibConfigurator.SAVE_MODE = {
    FILE = {}, 
    COMMENT = {}, 
    INSTR_COMMENT = {}, 
    NONE = {}, 
}

LibConfigurator.config = nil
LibConfigurator.filePath = nil
LibConfigurator.extraData = nil
LibConfigurator.saveMode = nil


--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------


function LibConfigurator:__init(saveMode, config, filePath)
    self.config = config
    self.filePath = filePath
    self.saveMode = saveMode
end

function LibConfigurator:setExtraData(extraData)
    self.extraData = extraData
end


function LibConfigurator:findCommentLine()
    local commentLines
    if (self.saveMode == self.SAVE_MODE.COMMENT) then
        commentLines = renoise.song().comments
    elseif (self.saveMode == self.SAVE_MODE.INSTR_COMMENT) then
        commentLines = self.extraData.comments
    end
    for x in pairs(commentLines) do
        if (string.find(commentLines[x], self.filePath) ~= nil) then
            return x
        end
    end
    return nil
end


function LibConfigurator:getConfigReal(options)
    if (options == nil) then
        options = {}
    end
    local data = ""
    if (self.saveMode == self.SAVE_MODE.COMMENT) then
        local commentLine = self:findCommentLine()
        if (commentLine ~= nil) then
            data = string.sub(renoise.song().comments[commentLine], string.len(self.filePath) + 2)
            if (options.asString ~= nil) then
                return data
            end 
        end
    elseif (self.saveMode == self.SAVE_MODE.INSTR_COMMENT) then
        local commentLine = self:findCommentLine()
        if (commentLine ~= nil) then
            data = string.sub(self.extraData.comments[commentLine], string.len(self.filePath) + 2)
            --print("instr comm "..self.extraData.name.. " "..data)
            if (options.asString ~= nil) then
                return data
            end 
        end
    elseif (self.saveMode == self.SAVE_MODE.FILE) then
        if (io.exists(self.filePath)) then
            local f = assert(io.open(self.filePath, "r"))
            data = f:read("*all")
            f:close()
            if (options.asString ~= nil) then
                return data
            end 
        end
    end
    if (string.len(data) > 0) then
        data = json.decode(data)
        if (data == nil) then
            data = {}
        end
    else
        data = {}
    end

    -- fill in default config
    for x in pairs(self.config) do
        if (data[x] == nil) then
            data[x] = self.config[x]
        end
    end
    return data
    --return self.config
end

function LibConfigurator:getConfigString()
    return self:getConfigReal({asString = true})
end

function LibConfigurator:getConfig()
    return self:getConfigReal({})
end

function LibConfigurator:getConfigWithOptions(options)
    return self:getConfigReal(options)
end



function LibConfigurator:setConfigReal(data, options)
    if (options == nil) then
        options = {}
    end
    if (self.saveMode == self.SAVE_MODE.COMMENT) then
        local commentLines = renoise.song().comments
        local comment = {}
        for x in pairs(commentLines) do
            comment[x] = commentLines[x]
        end
        local commentLine = self:findCommentLine()
        if (commentLine == nil) then
            commentLine = #comment
        end
        if (options.asString ~= nil) then
            data = self.filePath .. " " .. data
        else
            data = self.filePath .. " " .. json.encode(data)
        end
        comment[commentLine] = data
        renoise.song().comments = comment
    elseif (self.saveMode == self.SAVE_MODE.INSTR_COMMENT) then
        local commentLines = self.extraData.comments
        local comment = {}
        for x in pairs(commentLines) do
            comment[x] = commentLines[x]
        end
        local commentLine = self:findCommentLine()
        if (commentLine == nil) then
            commentLine = #comment
        end
        if (options.asString ~= nil) then
            data = self.filePath .. " " .. data
        else
            data = self.filePath .. " " .. json.encode(data)
        end
        comment[commentLine] = data
        self.extraData.comments = comment
    elseif (self.saveMode == self.SAVE_MODE.FILE) then
        local f = assert(io.open(self.filePath, "w"))
        if (options.asString ~= nil) then
            data = f:write(data)
        else
            data = f:write(json.encode(data))
        end
        f:close()
    end
end

function LibConfigurator:setConfigString(data)
    self:setConfigReal(data, {asString = true})
end

function LibConfigurator:setConfigWithOptions(data, options)
    self:setConfigReal(data, options)
end

function LibConfigurator:setConfig(data)
    self:setConfigReal(data, {})
end

function LibConfigurator:addMenu(title, desc, callbackRefresh)
    local vb = renoise.ViewBuilder()
    local data = self:getConfig()
    local dialogPtr, dialogView
    
    local dialogKeyHander = function(dialog, key)
        if key.name == "esc" then
            dialogPtr:close()
        else
            return key
        end
    end

    local lines = vb:vertical_aligner({})

    for index, val in pairs(desc) do
        if (val.type == "number") then
            lines:add_child(vb:horizontal_aligner {
                mode = "justify", 
                vb:text {
                    width = 160, 
                    text = index, 
                    tooltip = val.txt, 
                }, 
                vb:textfield {
                    id = "data_"..index, 
                    value = tostring(data[index]), 
                    width = 80, 
                    tooltip = val.txt, 
                    notifier = function(newValue)
                        if (tonumber(newValue) == nil) then
                            renoise.app():show_error("Only use numeric values in the field "..index.."!")
                            vb.views["data_"..index].value = tostring(data[index])
                        else
                            data[index] = tonumber(newValue)
                            if (callbackRefresh ~= nil) then
                                callbackRefresh(data)
                            end
                        end
                    end, 
                }, 
            })
        elseif (val.type == "boolean") then
            lines:add_child(vb:horizontal_aligner {
                mode = "justify", 
                vb:text {
                    width = 160, 
                    text = index, 
                    tooltip = val.txt, 
                }, 
                vb:checkbox {
                    id = "data_"..index, 
                    width = 80, 
                    value = data[index], 
                    tooltip = val.txt, 
                    notifier = function(newValue)
                        data[index] = newValue
                        if (callbackRefresh ~= nil) then
                            callbackRefresh(data)
                        end
                    end, 
                }, 
            })
        end
    end

    dialogView = vb:column {
        id = "container", 
        spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING, 
        margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN, 

        lines, 
        vb:horizontal_aligner {
            mode = "justify", 
            vb:button {
                text = "Save", 
                released = function()
                    self:setConfig(data)
                    if (callbackRefresh ~= nil) then
                        callbackRefresh(data)
                    end
                end
            }, 
            vb:button {
                text = "Close", 
                released = function()
                    dialogPtr:close()
                end
            }, 
            vb:button {
                text = "Set defaults", 
                released = function()
                    self:setConfig(self.config)
                    for index, val in pairs(desc) do
                        if (type(self.config[index]) == "string" or type(self.config[index]) == "number") then
                            vb.views["data_"..index].value = tostring(self.config[index])
                        elseif (type(self.config[index]) == "boolean") then
                            vb.views["data_"..index].value = self.config[index]
                        end
                    end
                    if (callbackRefresh ~= nil) then
                        callbackRefresh(self.config)
                    end
                end
            }, 
        }, 

    }

    renoise.tool():add_menu_entry ({
        name = "Main Menu:Tools:" .. title .. "...", 
        invoke = function() 
            dialogPtr = renoise.app():show_custom_dialog(title, dialogView, dialogKeyHander)
        end
    })

end


















