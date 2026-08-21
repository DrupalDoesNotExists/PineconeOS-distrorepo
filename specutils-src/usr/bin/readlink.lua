-- readlink: print the value of a symbolic link
-- Usage: readlink <path>
local args = {}
for i = 1, select("#", ...) do args[i] = select(i, ...) end

if #args < 1 then
    write(2, "usage: readlink <path>\n")
    exit(1)
end

local path = args[1]
local target, err = readlink(path)
if target then
    write(1, tostring(target) .. "\n")
else
    write(2, "readlink: " .. path .. ": " .. (err or "not a symbolic link") .. "\n")
    exit(1)
end
