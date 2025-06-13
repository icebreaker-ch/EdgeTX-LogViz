LIB_DIR = "/SCRIPTS/TOOLS/LogViz/"

local Selector = loadfile(LIB_DIR .. "selector.lua")()
local Button = loadfile(LIB_DIR .. "button.lua")()
local LogFiles = loadfile(LIB_DIR .. "logfiles.lua")()

local LEFT = 1
local SMALL_FONT_H = 8
local SMALL_FONT_W = 5
local EXCLUDE_FIELDS = { ["Date"] = true, ["Time"] = true }
local TIME_PATTERN = "(%d%d):(%d%d):(%d%d)%.(%d%d%d)"

local STATE_CHOICE_MODEL_SELECTED = 0
local STATE_CHOICE_MODEL_EDITING = 1
local STATE_CHOICE_FILE_SELECTED = 2
local STATE_CHOICE_FILE_EDITING = 3
local STATE_CHOICE_FIELD_SELECTED = 4
local STATE_CHOICE_FIELD_EDITING = 5
local STATE_BUTTON_EXIT_SELECTED = 6
local STATE_BUTTON_VIEW_SELECTED = 7
local STATE_PREPARE_VIEW = 8
local STATE_VIEW_LOG = 9

local SHOW_CURSOR_HINT_SECONDS = 1

-------------------
-- Helper functions
-------------------
local function map(value, sourceMin, sourceMax, targetMin, targetMax)
    return targetMin + (value - sourceMin) / (sourceMax - sourceMin) * (targetMax - targetMin)
end

local function round(value)
    return math.floor(value + 0.5)
end

local function toMilliSeconds(timeString)
    local hh, mm, ss, ddd
    hh, mm, ss, ddd = string.match(timeString, TIME_PATTERN)
    return 3600000 * tonumber(hh) + 60000 * tonumber(mm) + 1000 * tonumber(ss) + tonumber(ddd)
end

local function formatTime(milliSeconds)
    local hh = math.floor(milliSeconds / 3600000)
    milliSeconds = milliSeconds - hh * 3600000
    local mm = math.floor(milliSeconds / 60000)
    milliSeconds = milliSeconds - mm * 60000
    local ss = math.floor(milliSeconds / 1000)
    milliSeconds = milliSeconds - ss * 1000
    return string.format("%02d:%02d:%02d.%03d", hh, mm, ss, milliSeconds)
end

--------------------
-- Application class
--------------------
local LogViz = {}
LogViz.__index = LogViz

function LogViz.new()
    local self = setmetatable({}, LogViz)
    self.logFiles = LogFiles.new()
    self.modelSelector = Selector.new()
    self.fileSelector = Selector.new()
    self.fileSizeText = ""
    self.fieldSelector = Selector.new()
    self.exitButton = Button.new("Exit")
    self.viewButton = Button.new("View Log")
    self.modelSelector:setState(Selector.STATE_SELECTED)
    self.xMin = nil
    self.xMax = nil
    self.yMin = nil
    self.yMax = nil
    self.viewData = nil
    self.cursorPos = 0
    self.cursorTimer = nil
    self.state = STATE_CHOICE_MODEL_SELECTED
    return self
end

function LogViz:onModelChange(index)
    local model = self.modelSelector:getValue()
    local dates = self.logFiles:getDates(model)
    self.fileSelector:setValues(dates)
    self.fileSelector:setIndex(1)
end

function LogViz:onFileChange(index)
    local model = self.modelSelector:getValue()
    local logFile = self.logFiles:getFile(model, index)
    self.fileSizeText = string.format("%d", logFile:getSize())
    local fields = logFile:getFields(EXCLUDE_FIELDS)
    self.fieldSelector:setValues(fields)
    self.fieldSelector:setIndex(1)
end

function LogViz:init()
    self.logFiles:read()
    local models = self.logFiles:getModels()
    self.modelSelector:setOnChange(function(index) self:onModelChange(index) end)
    self.modelSelector:setValues(models)
    self.modelSelector:setIndex(1)

    self.fileSelector:setOnChange(function(index) self:onFileChange(index) end)
    self.modelSelector:setIndex(1)
end

function LogViz:run(event)
    local result = 0
    if self.state == STATE_CHOICE_MODEL_SELECTED then
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
    elseif self.state == STATE_PREPARE_VIEW then
        result = self:handlePrepareView(event)
    elseif self.state == STATE_VIEW_LOG then
        result = self:handleViewLog(event)
    end
    return result
end

function LogViz:handleModelSelected(event)
    if event == EVT_VIRTUAL_ENTER then
        self.modelSelector:setState(Selector.STATE_EDITING)
        self.state = STATE_CHOICE_MODEL_EDITING
    elseif event == EVT_VIRTUAL_NEXT then
        self.modelSelector:setState(Selector.STATE_IDLE)
        self.fileSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_FILE_SELECTED
    elseif event == EVT_VIRTUAL_PREV then
        self.modelSelector:setState(Selector.STATE_IDLE)
        self.viewButton:setState(Button.STATE_SELECTED)
        self.state = STATE_BUTTON_VIEW_SELECTED
    end
    self:updateUi()
    return 0
end

function LogViz:handleModelEditing(event)
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

function LogViz:handleFileSelected(event)
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

function LogViz:handleFileEditing(event)
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

function LogViz:handleFieldSelected(event)
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

function LogViz:handleFieldEditing(event)
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

function LogViz:handleButtonExitSelected(event)
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

function LogViz:handleButtonViewSelected(event)
    if event == EVT_VIRTUAL_ENTER then
        self.viewButton:setState(Button.STATE_IDLE)
        self:displayWaitMessage()
        self.state = STATE_PREPARE_VIEW
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

function LogViz:updateMinMax()
    self.yMin = nil
    self.yMax = nil
    for _, value in pairs(self.viewData) do
        if value then
            if not self.yMin or value < self.yMin then
                self.yMin = value
            end
            if not self.yMax or value > self.yMax then
                self.yMax = value
            end
        end
    end
end

function LogViz:updateView(showCursorHint)
    local field = self.fieldSelector:getValue()

    lcd.clear()
    local count = #self.viewData
    if self.yMin and self.yMax then
        lcd.drawText(0, 0, string.format("%.2f", self.yMax), SMLSIZE)
        lcd.drawText(0, LCD_H - SMALL_FONT_H, string.format("%.2f", self.yMin), SMLSIZE)
        lcd.drawText(LCD_W - SMALL_FONT_W * #field, 0, field, SMLSIZE)

        local lastX, lastY
        local pos = 0
        for _, value in pairs(self.viewData) do
            local x = round(map(pos, 0, count - 1, 0, LCD_W - 1))
            local y
            if self.yMax ~= self.yMin then
                y = round(map(value, self.yMin, self.yMax, LCD_H - 1, SMALL_FONT_H))
            else
                y = LCD_H / 2
            end
            if lastX and lastY then
                if x ~= lastX or y ~= lastY then
                    lcd.drawLine(lastX, lastY, x, y, SOLID, FORCE)
                end
            else
                lcd.drawPoint(x, y)
            end
            lastX, lastY = x, y
            pos = pos + 1
        end
        lcd.drawLine(self.cursorPos, SMALL_FONT_H, self.cursorPos, LCD_H - 1, DOTTED, FORCE)
        local index = round(map(self.cursorPos, 0, LCD_W - 1, 1, #self.viewData))
        local cursorValue = self.viewData[index]
        lcd.drawText(LCD_W / 2 - 3 * SMALL_FONT_W, 0, string.format("%.2f", cursorValue), SMLSIZE)

        if showCursorHint then
            local milliSeconds = round(map(self.cursorPos, 0, LCD_W - 1, self.xMin, self.xMax))
            local timeString = formatTime(milliSeconds)
            lcd.drawText(LCD_W / 2 - 6 * SMALL_FONT_W, LCD_H / 3 - SMALL_FONT_H, timeString, SMLSIZE + INVERS)
        end
    end
end

function LogViz:handlePrepareView(event)
    local model = self.modelSelector:getValue()
    local index = self.fileSelector:getIndex()
    local field = self.fieldSelector:getValue()
    local logFile = self.logFiles:getFile(model, index)

    self.viewData = {}
    local index = 1

    local minTimeString
    local maxTimeString
    local first = true
    for entry in logFile:entries(field) do
        self.viewData[index] = entry.value
        if first then
            minTimeString = entry.time
            first = false
        end
        maxTimeString = entry.time
        index = index + 1
    end
    self.cursorPos = 0
    self.cursorTimer = nil
    self.xMin = toMilliSeconds(minTimeString)
    self.xMax = toMilliSeconds(maxTimeString)
    self:updateMinMax()
    self:updateView(false)
    self.state = STATE_VIEW_LOG
    return 0
end

function LogViz:handleViewLog(event)
    if event == EVT_VIRTUAL_NEXT then
        self.cursorPos = self.cursorPos + 1
        if self.cursorPos > LCD_W - 1 then
            self.cursorPos = LCD_W - 1
        end
        self:updateView(true)
        self.cursorTimer = getRtcTime()
    elseif event == EVT_VIRTUAL_PREV then
        self.cursorPos = self.cursorPos - 1
        if self.cursorPos < 0 then
            self.cursorPos = 0
        end
        self:updateView(true)
        self.cursorTimer = getRtcTime()
    elseif event == EVT_VIRTUAL_EXIT then
        self.fieldSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_FIELD_SELECTED
    else
        if self.cursorTimer and getRtcTime() - self.cursorTimer > SHOW_CURSOR_HINT_SECONDS then
            self:updateView(false)
            self.cursorTimer = nil
        end
    end
    return 0
end

function LogViz:displayWaitMessage()
    lcd.clear()
    lcd.drawText(20, 20, "Reading values...")
    lcd.drawText(10, 30, "(can take a long time)")
end

function LogViz:updateUi()
    lcd.clear()
    lcd.drawText(LEFT, 0, "LogViz", INVERS)
    lcd.drawText(LEFT, 10, "Model:")
    lcd.drawText(35, 10, self.modelSelector:getValue(), self.modelSelector:getFlags())
    lcd.drawText(LEFT, 20, "File:")
    lcd.drawText(35, 20, self.fileSelector:getValue(), self.fileSelector:getFlags())
    lcd.drawText(LEFT, 30, "Size:")
    lcd.drawText(35, 30, self.fileSizeText)
    lcd.drawText(LEFT, 40, "Field:")
    lcd.drawText(35, 40, self.fieldSelector:getValue(), self.fieldSelector:getFlags())
    lcd.drawText(LEFT, 50, self.exitButton:getText(), self.exitButton:getFlags())
    lcd.drawText(35, 50, self.viewButton:getText(), self.viewButton:getFlags())
end

local logViewer = LogViz.new()

return { init = function() logViewer:init() end, run = function(event) return logViewer:run(event) end }
