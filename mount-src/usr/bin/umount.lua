-- umount: unmount a filesystem
-- Usage: umount <target>
-- Uses umount() syscall.

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args < 1 then
    write(2, "usage: umount <mountpoint>\n")
    exit(1)
end

local target = args[1]

-- check it's a directory
local st = stat(target)
if not st then
    write(2, "umount: '"..target.."' not found\n")
    exit(1)
end
if st.type ~= "directory" then
    write(2, "umount: '"..target.."' is not a mount point\n")
    exit(1)
end

local ok, err = umount(target)
if not ok then
    write(2, "umount: "..(err or "failed").."\n")
    exit(1)
end

write(1, "umounted "..target.."\n")
