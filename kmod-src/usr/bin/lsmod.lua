-- lsmod: list loaded kernel modules
-- Usage: lsmod
-- Reads /sys/modules to show currently loaded kernel modules.

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

-- read /sys/modules
local fd = open("/sys/modules", 0)
if not fd then
    write(2, "lsmod: cannot read /sys/modules\n")
    exit(1)
end

local chunks = {}
while true do
    local d = read(fd, 4096)
    if not d or #d == 0 then break end
    chunks[#chunks+1] = d
end
close(fd)

local data = table.concat(chunks)
if data == "" or data == "\n" then
    write(1, "No modules loaded.\n")
else
    -- parse module names from newline-separated list
    local mods = {}
    for name in data:gmatch("[^\n]+") do
        mods[#mods+1] = name
    end
    table.sort(mods)
    for _, name in ipairs(mods) do
        write(1, name.."\n")
    end
end
