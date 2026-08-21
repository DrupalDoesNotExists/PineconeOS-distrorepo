-- mkfifo: create a named pipe (FIFO)
-- Usage: mkfifo <path> [mode]
-- mode is an octal number, default 0644.
local args = {}
for i = 1, select("#", ...) do args[i] = select(i, ...) end

if #args < 1 then
    write(2, "usage: mkfifo <path> [mode]\n")
    exit(1)
end

local path = args[1]
local mode = 0x1A4  -- 0644 in decimal

if #args >= 2 then
    local mode_str = args[2]
    local octal = mode_str:match("^0[oO](.+)$") or mode_str:match("^0([0-7]+)$") or mode_str:match("^([0-7]+)$")
    if octal then
        mode = tonumber(octal, 8) or mode
    else
        write(2, "mkfifo: invalid mode: '" .. mode_str .. "'\n")
        exit(1)
    end
end

local ok, err = mkfifo(path, mode)
if not ok then
    write(2, "mkfifo: cannot create fifo '" .. path .. "': " .. (err or "failed") .. "\n")
    exit(1)
end
