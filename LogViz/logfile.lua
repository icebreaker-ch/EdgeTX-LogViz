LogFile = {}
LogFile.__index = LogFile

local PATTERN_FIELD = "[^,]+"
local PATTERN_LINE = "[^\n]+\n"
local BUFFER_SIZE = 512
local DATETIME_PATTERN = "(.*)%-(%d%d%d%d%-%d%d%-%d%d%-%d%d%d%d%d%d)%.csv$"
local PATH = "/LOGS"
local FIELD_DATE = "Date"
local FIELD_TIME = "Time"

function LogFile.new(fileName)
    local self = setmetatable({}, LogFile)
    self.fileName = fileName
    return self
end

-- Line iterator
-- Due to memory limitations, we have to read the file in buffered chunks
function LogFile:lines()
    local f = io.open(PATH .. "/" .. self.fileName, "r")
    local buffer = io.read(f, BUFFER_SIZE)
    local pos = 1
    return function()
        while buffer do
            local s, e = string.find(buffer, PATTERN_LINE, pos)
            if s and e then
                pos = e + 1
                return string.sub(buffer, s, e)
            else
                collectgarbage() -- reading new chunk is memory critical!
                local chunk = io.read(f, BUFFER_SIZE)
                if chunk and #chunk > 0 then
                    buffer = string.sub(buffer, pos, #buffer) .. chunk --append new chunk to buffer
                    pos = 1
                    chunk = nil -- try to help the gc
                    collectgarbage()
                else
                    buffer = nil
                    io.close(f)
                    collectgarbage()
                    return nil
                end
            end
        end
    end
end

-- Entries iterator returns entries, containing date, time and value
function LogFile:entries(field)
    local fields = {}
    local firstLine = true
    local lines = self:lines()

    return function()
        for line in lines do
            if firstLine then
                local index = 1
                for fieldName in string.gmatch(line, PATTERN_FIELD) do
                    fields[index] = fieldName
                    index = index + 1
                end
                firstLine = false
            else
                local entry = {}
                local fieldIndex = 1
                for value in string.gmatch(line, PATTERN_FIELD) do
                    if fields[fieldIndex] == FIELD_DATE then
                        entry.date = value
                    elseif fields[fieldIndex] == FIELD_TIME then
                        entry.time = value
                    elseif fields[fieldIndex] == field then
                        entry.value = tonumber(value)
                        return entry
                    end
                    fieldIndex = fieldIndex + 1
                end
            end
        end
        return nil
    end
end

function LogFile:getDate()
    local _, d = string.match(self.fileName, DATETIME_PATTERN)
    return d
end

function LogFile:getSize()
    return fstat(PATH .. "/" .. self.fileName).size
end

function LogFile:getFields(exclude)
    local fields = {}
    local firstLine = self:lines()()
    if firstLine then
        local index = 1
        for field in string.gmatch(firstLine, PATTERN_FIELD) do
            if not exclude or not exclude[field] then
                fields[index] = field
                index = index + 1
            end
        end
    end
    return fields
end

return LogFile
