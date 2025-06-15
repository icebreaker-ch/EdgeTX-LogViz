local LogFile = loadfile(LIB_DIR .. "logfile.lua")()

-- Class LogFiles
local LOG_DIR = "/LOGS"
local LOGFILE_PATTERN = "(.*)%-(%d%d%d%d%-%d%d%-%d%d)%-(%d%d%d%d%d%d)%.csv$"

local function append(table, entry)
    table[#table + 1] = entry
end


local LogFiles = {}
LogFiles.__index = LogFiles

function LogFiles.new()
    local self = setmetatable({}, LogFiles)
    return self
end

function LogFiles:read()
    local logFileCount = 0
    self.logFiles = {}
    for f in dir(LOG_DIR) do
        local model, date, time = string.match(f, LOGFILE_PATTERN)
        if model then
            if not self.logFiles[model] then
                self.logFiles[model] = {}
            end
            append(self.logFiles[model], LogFile.new(f))
            logFileCount = logFileCount + 1
        end
    end
    return logFileCount
end

function LogFiles:getModels()
    local models = {}
    for k, _ in pairs(self.logFiles) do
        append(models, k)
    end
    return models
end

function LogFiles:getFiles(model)
    return self.logFiles[model]
end

function LogFiles:getFile(model, index)
    return self.logFiles[model][index]
end

function LogFiles:getDates(model)
    local dates = {}
    for _,v in pairs(self.logFiles[model]) do
        append(dates, v:getDate())
    end
    return dates
end

return LogFiles
