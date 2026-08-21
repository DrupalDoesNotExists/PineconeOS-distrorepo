-- df: report disk free space
-- Usage: df [path]
-- KNUCK does not expose a VFS stat-size API to userspace,
-- so this prints a summary of known mounts.
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

write(1, string.format("%-16s %-10s %-10s %-10s %s\n",
    "Filesystem", "Size", "Used", "Avail", "Mounted on"))

-- Known mounts from kernel boot
local mounts = {
    { fs = "/dev/disk0", mp = "/" },
    { fs = "/dev/disk0", mp = "/boot" },
    { fs = "tmpfs",      mp = "/tmp" },
    { fs = "romfs",      mp = "/rom" },
    { fs = "devfs",      mp = "/dev" },
    { fs = "sysfs",      mp = "/sys" },
    { fs = "procfs",     mp = "/proc" },
}

for _, m in ipairs(mounts) do
    -- If a specific path was given, only show that mount
    if #args > 0 then
        local target = args[1]
        if target == m.mp or target:sub(1, #m.mp) == m.mp then
            write(1, string.format("%-16s %-10s %-10s %-10s %s\n",
                m.fs, "n/a", "n/a", "n/a", m.mp))
        end
    else
        write(1, string.format("%-16s %-10s %-10s %-10s %s\n",
            m.fs, "n/a", "n/a", "n/a", m.mp))
    end
end
