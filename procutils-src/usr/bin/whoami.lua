-- whoami: print current username
-- Usage: whoami
-- Uses getuid() and getpwnam() to resolve the username.
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

local uid = getuid()

-- Try to look up the username via getpwuid
local entry = getpwuid(uid)
if entry and entry.name then
    write(1, entry.name .. "\n")
else
    -- Fallback: numeric uid or "root" for uid 0
    if uid == 0 then
        write(1, "root\n")
    else
        write(1, tostring(uid) .. "\n")
    end
end
