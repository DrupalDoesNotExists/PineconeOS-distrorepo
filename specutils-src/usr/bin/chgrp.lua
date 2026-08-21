-- chgrp: change group ownership of files
-- Usage: chgrp <group> <file...>
-- <group> is a numeric GID.
local args = {}
for i = 1, select("#", ...) do args[i] = select(i, ...) end

if #args < 2 then
    write(2, "usage: chgrp <gid> <file...>\n")
    exit(1)
end

local gid = tonumber(args[1])
if not gid then
    write(2, "chgrp: invalid group id: '" .. args[1] .. "'\n")
    exit(1)
end

local rc = 0
for i = 2, #args do
    local path = args[i]
    local ok, err = chgrp(path, gid)
    if not ok then
        write(2, "chgrp: cannot change group of '" .. path .. "': " .. (err or "failed") .. "\n")
        rc = 1
    end
end

exit(rc)
