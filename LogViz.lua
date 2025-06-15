LIB_DIR = "/SCRIPTS/TOOLS/LogViz/"

local Selector = loadfile(LIB_DIR .. "selector.lua")()
local Button = loadfile(LIB_DIR .. "button.lua")()
local LogFiles = loadfile(LIB_DIR .. "logfiles.lua")()

local VERSION_STRING = "v1.0.2"

local LEFT = 1
local FONT_W
local FONT_H
local SMALL_FONT_W
local SMALL_FONT_H
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
local STATE_NO_FILES = 10

local SHOW_CURSOR_TOOLTIP_SECONDS = 1

local ALIGN_LEFT = 0
local ALIGN_CENTER = 1
local ALIGN_RIGHT = 2

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
    hh = hh % 24 -- handle midnight passing
    local mm = math.floor(milliSeconds / 60000)
    milliSeconds = milliSeconds - mm * 60000
    local ss = math.floor(milliSeconds / 1000)
    milliSeconds = milliSeconds - ss * 1000
    return string.format("%02d:%02d:%02d.%03d", hh, mm, ss, milliSeconds)
end

local function alignText(text, yPos, flags, align)
    local fontW
    if not flags or flags == 0 then
        fontW = FONT_W
    elseif flags & SMLSIZE then
        fontW = SMALL_FONT_W
    end
    local xPos
    if align == ALIGN_LEFT then
        xPos = 0
    elseif align == ALIGN_CENTER then
        xPos = (LCD_W - #text * fontW) / 2
    elseif align == ALIGN_RIGHT then
        xPos = LCD_W - 1 - #text * fontW
    end
    lcd.drawText(xPos, yPos, text, flags)
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

function LogViz:initScreen()
    if lcd.RGB then
        FONT_W, FONT_H = lcd.sizeText("Wg")
        FONT_W = FONT_W / 2
        SMALL_FONT_W, SMALL_FONT_H = lcd.sizeText("Wg", SMLSIZE)
        SMALL_FONT_W = SMALL_FONT_W / 2
    else
        FONT_W = 5
        FONT_H = 7
        SMALL_FONT_W = 4
        SMALL_FONT_H = 6
    end
end

function LogViz:init()
    self:initScreen()
    self.logFileCount = self.logFiles:read()
    if self.logFileCount > 0 then
        local models = self.logFiles:getModels()
        self.modelSelector:setOnChange(function(index) self:onModelChange(index) end)
        self.modelSelector:setValues(models)
        self.modelSelector:setIndex(1)

        self.fileSelector:setOnChange(function(index) self:onFileChange(index) end)
        self.modelSelector:setIndex(1)
    else
        self.state = STATE_NO_FILES
    end
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
    elseif self.state == STATE_NO_FILES then
        result = self:handleNoFiles(event)
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

function LogViz:updateView(showToolTip)
    local field = self.fieldSelector:getValue()

    lcd.clear()
    local count = #self.viewData
    if self.yMin and self.yMax then
        alignText(string.format("%.2f", self.yMax), 0, SMLSIZE, ALIGN_LEFT)
        alignText(string.format("%.2f", self.yMin), LCD_H - SMALL_FONT_H, SMLSIZE, ALIGN_LEFT)
        alignText(field, 0, SMLSIZE, ALIGN_RIGHT)

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
        local cursorValString = string.format("%.2f", self.viewData[index])
        alignText(cursorValString, 0, SMLSIZE, ALIGN_CENTER)

        if showToolTip then
            local milliSeconds = round(map(self.cursorPos, 0, LCD_W - 1, self.xMin, self.xMax))
            local timeString = formatTime(milliSeconds)
            alignText(timeString, LCD_H / 3 - SMALL_FONT_H, SMLSIZE + INVERS, ALIGN_CENTER)
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
    if self.xMax < self.xMin then                   -- passed midnight
        self.xMax = self.xMax + 24 * 60 * 60 * 1000 -- add 24 hours
    end
    self:updateMinMax()
    self:updateView(false)
    self.state = STATE_VIEW_LOG
    return 0
end

function LogViz:changeCursorPos(offset)
    self.cursorPos = self.cursorPos + offset
    if self.cursorPos > LCD_W - 1 then
        self.cursorPos = LCD_W - 1
    elseif self.cursorPos < 0 then
        self.cursorPos = 0
    end
    self:updateView(true)
    self.cursorTimer = getRtcTime()
end

function LogViz:handleViewLog(event)
    if event == EVT_VIRTUAL_NEXT then
        self:changeCursorPos(1)
    elseif event == EVT_VIRTUAL_PREV then
        self:changeCursorPos(-1)
    elseif event == EVT_VIRTUAL_EXIT then
        self.fieldSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_FIELD_SELECTED
    elseif event == EVT_VIRTUAL_ENTER then
        self:changeCursorPos(0)
    else
        local stick = getSourceValue(1) -- Navigate by stick
        if stick > 100 then
            self:changeCursorPos(stick / 100)
        elseif stick < -100 then
            self:changeCursorPos(stick / 100)
        end
    end
    if self.cursorTimer and getRtcTime() - self.cursorTimer > SHOW_CURSOR_TOOLTIP_SECONDS then
        self:updateView(false)
        self.cursorTimer = nil
    end
    return 0
end

function LogViz:displayWaitMessage()
    lcd.clear()
    local yPos = 20
    alignText("Reading values...", yPos, 0, ALIGN_CENTER)
    yPos = yPos + FONT_H + 2
    alignText("(can take a long time)", yPos, 0, ALIGN_CENTER)
end

function LogViz:handleNoFiles(event)
    lcd.clear()
    alignText("No Log Files found", LCD_H / 2 - FONT_H, 0, ALIGN_CENTER)
    alignText("Press RTN to exit", LCD_H / 2 + FONT_H, 0, ALIGN_CENTER)
    if event == EVT_VIRTUAL_EXIT then
        return 1
    end
    return 0
end

function LogViz:updateUi()
    local COL = { LEFT, 7 * FONT_W }
    local yPos = 0
    lcd.clear()
    lcd.drawText(COL[1], yPos, "LogViz", INVERS)
    alignText(VERSION_STRING, yPos, SMLSIZE, ALIGN_RIGHT)
    yPos = yPos + FONT_H + 2
    lcd.drawText(COL[1], yPos, "Model:")
    lcd.drawText(COL[2], yPos, self.modelSelector:getValue(), self.modelSelector:getFlags())
    yPos = yPos + FONT_H + 2
    lcd.drawText(COL[1], yPos, "File:")
    lcd.drawText(COL[2], yPos, self.fileSelector:getValue(), self.fileSelector:getFlags())
    yPos = yPos + FONT_H + 2
    lcd.drawText(COL[1], yPos, "Size:")
    lcd.drawText(COL[2], yPos, self.fileSizeText)
    yPos = yPos + FONT_H + 2
    lcd.drawText(COL[1], yPos, "Field:")
    lcd.drawText(COL[2], yPos, self.fieldSelector:getValue(), self.fieldSelector:getFlags())
    yPos = yPos + FONT_H + 10
    lcd.drawText(COL[1], yPos, self.exitButton:getText(), self.exitButton:getFlags())
    lcd.drawText(COL[2], yPos, self.viewButton:getText(), self.viewButton:getFlags())
end

local logViz = LogViz.new()

return { init = function() logViz:init() end, run = function(event) return logViz:run(event) end }
