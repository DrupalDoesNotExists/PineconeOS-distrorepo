-- mount: show mounted filesystems
-- Usage: mount
-- Reads /proc/mounts if available, otherwise prints known virtual mounts.
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

-- Try /proc/mounts first
local fd = open("/proc/mounts", 0)
if fd then
    local chunks = {}
    while true do
        local d = read(fd, 4096)
        if not d or #d == 0 then break end
        chunks[#chunks+1] = d
    end
    close(fd)
    write(1, table.concat(chunks))
else
    -- No /proc/mounts; report what the kernel boots with by default
    write(1, "/          disk\n")
    write(1, "/boot      disk\n")
    write(1, "/tmp       tmp\n")
    write(1, "/rom       rom\n")
    write(1, "/dev       dev\n")
    write(1, "/sys       sys\n")
    write(1, "/proc      proc\n")
end
