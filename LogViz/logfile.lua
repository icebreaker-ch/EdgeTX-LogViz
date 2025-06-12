LogFile = {}
LogFile.__index = LogFile

local EOL = '\n'
local SEP = ','
local PATTERN_FIELD = "[^,]+"
local PATTERN_LINE = "[^\n]+\n"
local BUFFER_SIZE = 1024
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

    return function()
        while buffer do
            local s, e = string.find(buffer, PATTERN_LINE)
            if s and e then
                local line = string.sub(buffer, s, e)
                buffer = string.sub(buffer, e + 1, #buffer) -- set buffer to not processed chars
                return (line)
            else
                local chunk = io.read(f, BUFFER_SIZE)
                if chunk and #chunk > 0 then
                    buffer = buffer .. chunk --append buffer
                else
                    buffer = nil
                    io.close(f)
                    return nil
                end
            end
        end
    end
end

-- Values iterator returns key/value table
function LogFile:entries(field)
    local fields = {}
    local firstLine = true
    local lines = self:lines()

    return function()
        for line in lines do
            if firstLine then
                local index = 1
                for field in string.gmatch(line, PATTERN_FIELD) do
                    fields[index] = field
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
