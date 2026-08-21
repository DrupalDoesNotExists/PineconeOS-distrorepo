-- uptime: show system uptime
-- Usage: uptime
-- Reads /proc/uptime if available, else uses clock() syscall.
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

-- Try /proc/uptime first
local fd = open("/proc/uptime", 0)
if fd then
    local chunks = {}
    while true do
        local d = read(fd, 4096)
        if not d or #d == 0 then break end
        chunks[#chunks+1] = d
    end
    close(fd)
    local raw = table.concat(chunks):match("^(%S+)")
    local secs = tonumber(raw)
    if secs then
        local days = math.floor(secs / 86400)
        local hours = math.floor((secs % 86400) / 3600)
        local mins = math.floor((secs % 3600) / 60)
        write(1, string.format(" up %d days, %02d:%02d\n", days, hours, mins))
        return
    end
end

-- Fallback: try clock() syscall
local ok, t = pcall(function() return clock() end)
if ok and t then
    local secs = math.floor(t)
    local days = math.floor(secs / 86400)
    local hours = math.floor((secs % 86400) / 3600)
    local mins = math.floor((secs % 3600) / 60)
    write(1, string.format(" up %d days, %02d:%02d\n", days, hours, mins))
else
    write(1, "up unknown (no uptime data available)\n")
end
