-- insmod: load a kernel module
-- Usage: insmod <path.lua>
-- Loads a Lua kernel module file via the insmod() syscall.
-- Requires root (uid=0).

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args < 1 then
    write(2, "usage: insmod <module.lua>\n")
    exit(1)
end

local path = args[1]

-- check file exists
local st = stat(path)
if not st then
    write(2, "insmod: cannot open '"..path.."': No such file or directory\n")
    exit(1)
end

local ok, err = insmod(path)
if not ok then
    write(2, "insmod: "..(err or "failed to load module").."\n")
    exit(1)
end

write(1, "insmod: loaded "..path.."\n")
