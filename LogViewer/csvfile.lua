CSVFile = {}
CSVFile.__index = CSVFile

local EOL = '\n'
local SEP = ','
local PATTERN_FIELD = "[^,]+"
local PATTERN_LINE = "[^\n]+\n"
local BUFFER_SIZE = 128
local DATETIME_PATTERN = "(.*)%-(%d%d%d%d%-%d%d%-%d%d%-%d%d%d%d%d%d)%.csv$"
local PATH = "/LOGS"


function CSVFile.new(fileName)
    local self = setmetatable({}, CSVFile)
    self.fileName = fileName
    return self
end

-- Line iterator
-- Due to memory limitations, we have to read the file in buffered chunks
function CSVFile:lines() 
    local f = io.open(PATH .."/" .. self.fileName, "r")
    local buffer = io.read(f, BUFFER_SIZE)

    return function()
        while buffer and #buffer > 0 do
            local s,e = string.find(buffer, PATTERN_LINE)
            if s and e then
                local line = string.sub(buffer, s, e)
                buffer = string.sub(buffer, e + 1, #buffer) -- set buffer to not processed chars
                return(line)
            else
                local chunk = io.read(f, BUFFER_SIZE)
                if chunk then
                    buffer = buffer .. chunk --append buffer
                else
                    buffer = nil
                    io.close(f)
                end
            end
        end
    end
end

-- Values iterator returns key/value table
function CSVFile:values()
    local keys = {}
    local f = io.open(PATH .. "/" .. self.fileName, "r")
    local firstLine = true
    local lines = self:lines()

    return function()
        for line in lines do
            local index = 1
            if firstLine then
                for key in string.gmatch(line, PATTERN_FIELD) do
                    keys[index] = key
                    index = index + 1
                end
                firstLine = false
            else
                local values = {}
                for value in string.gmatch(line, PATTERN_FIELD) do
                    values[keys[index]] = tonumber(value)
                    index = index + 1
                end
                return values
            end
        end
        return nil
    end
end

function CSVFile:getValues(line)
    local values = {}
    local index = 1
    for value in string.gmatch(line, PATTERN_FIELD) do
        values[index] = tonumber(value)
        index = index + 1
    end
    return values
end

function CSVFile:getDate()
    local _,d = string.match(self.fileName, DATETIME_PATTERN)
    return d
end

function CSVFile:getFields()
    local fields = {}
    local firstLine = self:lines()()
    local index = 1
    for field in string.gmatch(firstLine, PATTERN_FIELD) do
        fields[index] = field
        index = index + 1
    end
    return fields
end

return CSVFile