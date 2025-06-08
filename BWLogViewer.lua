local CSVFile = loadfile("/SCRIPTS/TOOLS/LogViewer/csvfile.lua")()
local Selector = loadfile("/SCRIPTS/TOOLS/LogViewer/selector.lua")()
local Button = loadfile("/SCRIPTS/TOOLS/LogViewer/button.lua")()
local LogFiles = loadfile("/SCRIPTS/TOOLS/LogViewer/logfiles.lua")()

local STATE_IDLE = 0
local STATE_CHOICE_MODEL_SELECTED = 1
local STATE_CHOICE_MODEL_EDITING = 2
local STATE_CHOICE_FILE_SELECTED = 3
local STATE_CHOICE_FILE_EDITING = 4
local STATE_CHOICE_FIELD_SELECTED = 5
local STATE_CHOICE_FIELD_EDITING = 6
local STATE_BUTTON_EXIT_SELECTED = 7
local STATE_BUTTON_VIEW_SELECTED = 8
local STATE_VIEW_LOG = 9

local LogViewer = {}
LogViewer.__index = LogViewer

function LogViewer.new()
    local self = setmetatable({}, LogViewer)
    self.logFiles = LogFiles.new()
    self.modelSelector = Selector.new()
    self.fileSelector = Selector.new()
    self.fieldSelector = Selector.new()
    self.exitButton = Button.new("Exit")
    self.viewButton = Button.new("View Log")
    self.state = STATE_IDLE
    return self
end

function LogViewer:onModelChange(index)
    local model = self.modelSelector:getValue()
    local dates = self.logFiles:getDates(model)
    self.fileSelector:setValues(dates)
    self.fileSelector:setIndex(1)
end

function LogViewer:onFileChange(index)
    local model = self.modelSelector:getValue()
    local logFile = self.logFiles:getFile(model, index)
    local fields = logFile:getFields()
    self.fieldSelector:setValues(fields)
    self.fieldSelector:setIndex(1)
end

function LogViewer:init()
    self.logFiles:read()
    local models = self.logFiles:getModels()
    self.modelSelector:setOnChange(function(index) self:onModelChange(index) end)
    self.modelSelector:setValues(models)
    self.modelSelector:setIndex(1)

    self.fileSelector:setOnChange(function(index) self:onFileChange(index) end)
    self.modelSelector:setIndex(1)
end

function LogViewer:run(event)
    local result = 0
    if self.state == STATE_IDLE then
        result = self:handleIdle(event)
    elseif self.state == STATE_CHOICE_MODEL_SELECTED then
        result = self:handleModelSelected(event)
    elseif self.state == STATE_CHOICE_MODEL_EDITING then
        result = self:handleModelEditing(event)
    elseif self.state == STATE_CHOICE_FILE_SELECTED then
        result = self:handleFileSelected(event)
    elseif self.state == STATE_CHOICE_FILE_EDITING then
        result = self:handleFileEditing(event)
    elseif self.state == STATE_CHOICE_FIELD_SELECTED then
        result = self:handleFieldSelected(event)
    elseif self.state == STATE_CHOICE_FIELD_EDITING then
        result = self:handleFieldEditing(event)
    elseif self.state == STATE_BUTTON_EXIT_SELECTED then
        result = self:handleButtonExitSelected(event)
    elseif self.state == STATE_BUTTON_VIEW_SELECTED then
        result = self:handleButtonViewSelected(event)
    elseif self.state == STATE_VIEW_LOG then
        result = self:handleViewLog(event)
    end
    return result
end

function LogViewer:handleIdle(event)
    if event == EVT_VIRTUAL_NEXT then
        self.modelSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_MODEL_SELECTED
    end
    self:updateUi()
    return 0
end

function LogViewer:handleModelSelected(event)
    if event == EVT_VIRTUAL_ENTER then
        self.modelSelector:setState(Selector.STATE_EDITING)
        self.state = STATE_CHOICE_MODEL_EDITING
    elseif event == EVT_VIRTUAL_NEXT then
        self.modelSelector:setState(Selector.STATE_IDLE)
        self.fileSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_FILE_SELECTED
    elseif event == EVT_VIRTUAL_PREV then
        self.modelSelector:setState(Selector.STATE_IDLE)
        self.fieldSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_FIELD_SELECTED
    end
    self:updateUi()
    return 0
end

function LogViewer:handleModelEditing(event)
    if event == EVT_VIRTUAL_NEXT then
        self.modelSelector:incValue()
    elseif event == EVT_VIRTUAL_PREV then
        self.modelSelector:decValue()
    elseif event == EVT_VIRTUAL_ENTER then
        self.modelSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_MODEL_SELECTED
    end
    self:updateUi()
    return 0
end

function LogViewer:handleFileSelected(event)
    if event == EVT_VIRTUAL_ENTER then
        self.fileSelector:setState(Selector.STATE_EDITING)
        self.state = STATE_CHOICE_FILE_EDITING
    elseif event == EVT_VIRTUAL_NEXT then
        self.fileSelector:setState(Selector.STATE_IDLE)
        self.fieldSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_FIELD_SELECTED
    elseif event == EVT_VIRTUAL_PREV then
        self.fileSelector:setState(Selector.STATE_IDLE)
        self.modelSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_MODEL_SELECTED
    end
    self:updateUi()
    return 0
end

function LogViewer:handleFileEditing(event)
    if event == EVT_VIRTUAL_NEXT then
        self.fileSelector:incValue()
    elseif event == EVT_VIRTUAL_PREV then
        self.fileSelector:decValue()
    elseif event == EVT_VIRTUAL_ENTER then
        self.fileSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_FILE_SELECTED
    end
    self:updateUi()
    return 0
end

function LogViewer:handleFieldSelected(event)
    if event == EVT_VIRTUAL_ENTER then
        self.fieldSelector:setState(Selector.STATE_EDITING)
        self.state = STATE_CHOICE_FIELD_EDITING
    elseif event == EVT_VIRTUAL_NEXT then
        self.fieldSelector:setState(Selector.STATE_IDLE)
        self.exitButton:setState(Button.STATE_SELECTED)
        self.state = STATE_BUTTON_EXIT_SELECTED
    elseif event == EVT_VIRTUAL_PREV then
        self.fieldSelector:setState(Selector.STATE_IDLE)
        self.fileSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_FILE_SELECTED
    end
    self:updateUi()
    return 0
end

function LogViewer:handleFieldEditing(event)
    if event == EVT_VIRTUAL_NEXT then
        self.fieldSelector:incValue()
    elseif event == EVT_VIRTUAL_PREV then
        self.fieldSelector:decValue()
    elseif event == EVT_VIRTUAL_ENTER then
        self.fieldSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_FIELD_SELECTED
    end
    self:updateUi()
    return 0
end

function LogViewer:handleButtonExitSelected(event)
    if event == EVT_VIRTUAL_ENTER then
        self.exitButton:setState(Button.STATE_SELECTED)
        return 1 -- Exit
    elseif event == EVT_VIRTUAL_NEXT then
        self.exitButton:setState(Button.STATE_IDLE)
        self.viewButton:setState(Button.STATE_SELECTED)
        self.state = STATE_BUTTON_VIEW_SELECTED
    elseif event == EVT_VIRTUAL_PREV then
        self.exitButton:setState(Button.STATE_IDLE)
        self.fieldSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_FIELD_SELECTED
    end
    self:updateUi()
    return 0
end

function LogViewer:handleButtonViewSelected(event)
    if event == EVT_VIRTUAL_ENTER then
        self.viewButton:setState(Button.STATE_SELECTED)
        self:updateLogView()
        self.state = STATE_VIEW_LOG
    elseif event == EVT_VIRTUAL_NEXT then
        self.viewButton:setState(Button.STATE_IDLE)
        self.modelSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_MODEL_SELECTED;
        self:updateUi()
    elseif event == EVT_VIRTUAL_PREV then
        self.viewButton:setState(Button.STATE_IDLE)
        self.exitButton:setState(Selector.STATE_SELECTED)
        self.state = STATE_BUTTON_EXIT_SELECTED
        self:updateUi()
    end
    return 0
end

function LogViewer:handleViewLog(event)
    if event == EVT_VIRTUAL_EXIT then
        self.state = STATE_IDLE
    end
    return 0
end

local function getMinMax(values)
    local min
    local max
    for _, v in pairs(values) do
        local val = tonumber(v)
        if val then
            if not min or val < min then
                min = val
            end
            if not max or val > max then
                max = val
            end
        end
    end
    return min, max
end

function LogViewer:updateLogView()
    local model = self.modelSelector:getValue()
    local index = self.fileSelector:getIndex()
    local field = self.fieldSelector:getValue()
    local logFile = self.logFiles:getFile(model, index)

    local fieldValues = {}
    local index = 1

    lcd.clear()

    for map in logFile:values() do
        fieldValues[index] = map[field]
        index = index + 1
    end

    local min, max = getMinMax(fieldValues)
    local count = #fieldValues
    if min and max then
        local pos = 0
        for _, v in pairs(fieldValues) do
            local x = math.floor(pos / count * LCD_W)
            local y = LCD_H - math.floor((v - min) / (max - min) * LCD_H)
            lcd.drawPoint(x, y)
            pos = pos + 1
        end
    end
end

function LogViewer:updateUi()
    local LEFT = 0

    lcd.clear()
    lcd.drawText(LEFT, 0, "LogViewer", INVERS)
    lcd.drawText(LEFT, 10, "Model:")
    lcd.drawText(35, 10, self.modelSelector:getValue(), self.modelSelector:getFlags())
    lcd.drawText(LEFT, 20, "File:")
    lcd.drawText(35, 20, self.fileSelector:getValue(), self.fileSelector:getFlags())
    lcd.drawText(LEFT, 30, "Field:")
    lcd.drawText(35, 30, self.fieldSelector:getValue(), self.fieldSelector:getFlags())
    lcd.drawText(LEFT, 50, self.exitButton:getText(), self.exitButton:getFlags())
    lcd.drawText(35, 50, self.viewButton:getText(), self.viewButton:getFlags())
end

local logViewer = LogViewer.new()

return { init = function() logViewer:init() end, run = function(event) return logViewer:run(event) end }
