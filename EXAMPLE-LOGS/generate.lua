#!/usr/bin/env lua

local start = os.time({year=2025, month=6, day=15, hour=23, min=59, sec=0})

local file = io.open("Generic-2025-06-16-235900.csv", "w")
file:write("Date,Time,Val\n")
for s = 0,360 do
    dt = os.date("*t", start + s)
    val = math.sin(s / 360 * 2 * math.pi)
    file:write(string.format("%04d-%02d-%02d,%02d:%02d:%02d.000,%.2f\n", dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec, val))
end
file:close()