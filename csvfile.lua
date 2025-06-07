CSVFile = {}
CSVFile.__index = CSVFile

function CSVFile.new(path)
    local self = setmetatable({}, CSVFile)
    self.EOL = '\n'
    self.SEP = ','
    self.path = path
    return self
end

-- Line iterator
function CSVFile:lines()
    local f = io.open(self.path, "r")

    return function()
        local line = {}
        local pos = 1
        repeat
            local c = f:read(1)
            if c ~= nil and c ~= self.EOL then
                line[pos] = c
                pos = pos + 1
            end
        until c== nil or c == self.EOL
        if #line > 0 then
           return table.concat(line)
        else
            io.close(f)
            return nil
        end
    end
end

function CSVFile:getValues(line)
    local values = {}
    local index = 1
    for value in string.gmatch(line, "[^,]+") do
        values[index] = value
        index = index + 1
    end
    return values
end

function CSVFile:getFields()
    local f = io.open(self.path, "r")
    local fields = {}
    local index = 1

    if f then
        local field = {}
        local pos = 1
        repeat
            local c = f:read(1)
            if c ~= self.EOL and c ~= self.SEP then
                field[pos] = c
                pos = pos + 1
            else
                field[pos] = nil
                fields[index] = table.concat(field)
                index = index + 1
                pos = 1
            end
        until c == self.EOL
        io.close(f)
    end
    return fields
end

local path = "LOGS/Allusive-2025-05-16-064229.csv"

local csv = CSVFile.new(path)
local fields = csv:getFields()
for _, f in pairs(fields) do
    print(f)
end

for l in csv:lines() do
    print(l)
    local values = csv:getValues(l)
    for _,v in pairs(values) do
        print(v)
    end
end
