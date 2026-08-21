-- rmmod: unload a kernel module
-- Usage: rmmod <module-name>
-- Removes a loaded kernel module via the rmmod() syscall.
-- Requires root (uid=0).

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args < 1 then
    write(2, "usage: rmmod <module-name>\n")
    exit(1)
end

local name = args[1]

local ok, err = rmmod(name)
if not ok then
    write(2, "rmmod: "..(err or "failed to unload module").."\n")
    exit(1)
end

write(1, "rmmod: unloaded "..name.."\n")
