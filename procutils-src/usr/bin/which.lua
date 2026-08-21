-- which: locate a command in PATH
-- Usage: which command...
-- Searches /usr/bin, /bin, /sbin, /usr/sbin for the given commands.
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args == 0 then
    write(2, "usage: which command...\n")
    exit(1)
end

local path_dirs = { "/usr/bin", "/bin", "/sbin", "/usr/sbin" }

local rc = 0
for _, cmd in ipairs(args) do
    local found = false
    for _, dir in ipairs(path_dirs) do
        for _, cand in ipairs({ cmd, cmd .. ".lua" }) do
            local full = dir .. "/" .. cand
            local st = stat(full)
            if st and st.type == "file" then
                write(1, full .. "\n")
                found = true
                break
            end
        end
        if found then break end
    end
    if not found then
        write(2, cmd .. " not found\n")
        rc = 1
    end
end

exit(rc)
