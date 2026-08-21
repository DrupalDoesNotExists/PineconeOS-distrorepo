-- sleep: suspend execution for a specified duration
-- Usage: sleep <seconds>
-- Supports fractional seconds (e.g. 0.5).
local args = {}
for i = 1, select("#", ...) do args[i] = select(i, ...) end

if #args < 1 then
    write(2, "usage: sleep <seconds>\n")
    exit(1)
end

local secs = tonumber(args[1])
if not secs or secs < 0 then
    write(2, "sleep: invalid time interval '" .. args[1] .. "'\n")
    exit(1)
end

sleep(secs)
