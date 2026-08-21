-- ps: list running processes
-- Usage: ps
-- Reads /proc entries to discover processes.
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

-- Read /proc directory for pid entries
local entries = readdir("/proc")
if not entries then
    write(2, "ps: cannot read /proc\n")
    exit(1)
end

write(1, string.format("%-8s %-8s %-8s %-8s %s\n", "PID", "PPID", "UID", "STATE", "NAME"))

local count = 0
for _, e in ipairs(entries) do
    local name = e.name
    local pid = tonumber(name)
    if pid then
        -- Read /proc/<pid>/status
        local fd = open("/proc/" .. pid .. "/status", 0)
        if fd then
            local chunks = {}
            while true do
                local d = read(fd, 4096)
                if not d or #d == 0 then break end
                chunks[#chunks+1] = d
            end
            close(fd)
            local data = table.concat(chunks)

            local pname = "?"
            local pstate = "?"
            local ppid = "?"
            local puid = "?"

            for line in data:gmatch("[^\n]+") do
                local k, v = line:match("^(%S+):%s+(.+)$")
                if k == "Name" then pname = v
                elseif k == "State" then pstate = v
                elseif k == "PPid" then ppid = v
                elseif k == "Uid" then puid = v
                end
            end

            write(1, string.format("%-8s %-8s %-8s %-8s %s\n", pid, ppid, puid, pstate, pname))
            count = count + 1
        end
    end
end

if count == 0 then
    write(1, "ps: no processes found\n")
end
