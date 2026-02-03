#!/usr/bin/env lua


local file = io.open("EXAMPLE-LOGS/PassMidnight-2025-06-16-235900.csv", "w")
if file then
    local start = os.time({ year = 2025, month = 6, day = 15, hour = 23, min = 59, sec = 0 })
    file:write("Date,Time,Val\n")
    for s = 0, 360 do
        local dt = os.date("*t", start + s)
        local val = math.sin(s / 360 * 2 * math.pi)
        file:write(string.format("%04d-%02d-%02d,%02d:%02d:%02d.000,%.2f\n", dt.year, dt.month, dt.day, dt.hour, dt.min,
            dt.sec, val))
    end
    file:close()
end

file = io.open("EXAMPLE-LOGS/LargeFile-2025-07-01-120000.csv", "w")
if file then
    local start = os.time({ year = 2025, month = 7, day = 1, hour = 12, min = 00, sec = 0 })
    file:write("Date,Time,Val\n")
    for h = 0, 1 do
        for m = 0, 59 do
            for s = 0, 59 do
                local dt = os.date("*t", start + 3600 * h + 60 * m + s)
                local val = math.sin((m + s / 60) / 60 * 2 * math.pi)
                file:write(string.format("%04d-%02d-%02d,%02d:%02d:%02d.000,%.2f\n", dt.year, dt.month, dt.day, dt.hour,
                    dt.min, dt.sec, val))
            end
        end
    end
    file:close()
end
