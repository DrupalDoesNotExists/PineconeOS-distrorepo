-- uname: print system information
-- Usage: uname [-a] [-s] [-r] [-n] [-m]
-- Reads /proc/version when available.
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

local show_all = false
local show_sysname = false
local show_release = false
local show_nodename = false
local show_machine = false

if #args == 0 then
    show_sysname = true
else
    for _, a in ipairs(args) do
        if a == "-a" then
            show_all = true
        elseif a == "-s" then show_sysname = true
        elseif a == "-r" then show_release = true
        elseif a == "-n" then show_nodename = true
        elseif a == "-m" then show_machine = true
        elseif a:sub(1,1) == "-" and #a > 1 then
            for j=2,#a do
                local c = a:sub(j,j)
                if c == "a" then show_all = true
                elseif c == "s" then show_sysname = true
                elseif c == "r" then show_release = true
                elseif c == "n" then show_nodename = true
                elseif c == "m" then show_machine = true
                else
                    write(2, "uname: unknown option: -" .. c .. "\n")
                    exit(1)
                end
            end
        end
    end
end

if show_all then
    show_sysname = true
    show_release = true
    show_nodename = true
    show_machine = true
end

-- Read kernel version from /proc/version
local kernel_version = "KNUCK"
local fd = open("/proc/version", 0)
if fd then
    local chunks = {}
    while true do
        local d = read(fd, 4096)
        if not d or #d == 0 then break end
        chunks[#chunks+1] = d
    end
    close(fd)
    kernel_version = table.concat(chunks):match("^(%S+)") or "KNUCK"
end

local parts = {}
if show_sysname then parts[#parts+1] = kernel_version end
if show_nodename then parts[#parts+1] = "knuck" end
if show_release then parts[#parts+1] = "1.0" end
if show_machine then parts[#parts+1] = "lua52" end

if #parts == 0 then
    parts[1] = kernel_version
end

write(1, table.concat(parts, " ") .. "\n")
