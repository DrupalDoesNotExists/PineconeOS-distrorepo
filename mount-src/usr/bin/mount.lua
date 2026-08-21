-- mount: mount a filesystem or show mounts
-- Usage: mount [source] <target> [fstype] [-o options]
--        mount (no args: show mounted filesystems)
-- Uses mount() syscall for actual mounting.

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

-- show mounts when no arguments
if #args == 0 then
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
        write(1, "/          disk\n")
        write(1, "/boot      disk\n")
        write(1, "/tmp       tmp\n")
        write(1, "/rom       rom\n")
        write(1, "/dev       dev\n")
        write(1, "/sys       sys\n")
        write(1, "/proc      proc\n")
    end
    return
end

-- parse arguments: mount [source] <target> [fstype] [-o options]
local source = nil
local target = nil
local fstype = nil
local flags = nil
local positional = {}

for i=1,#args do
    local a = args[i]
    if a == "-o" and i < #args then
        flags = args[i+1]
        i = i + 1
    elseif a:sub(1,2) == "-o" then
        flags = a:sub(3)
    else
        positional[#positional+1] = a
    end
end

if #positional < 1 then
    write(2, "usage: mount [source] <target> [fstype] [-o options]\n")
    exit(1)
end

if #positional == 1 then
    -- mount <target> — assume generic mount
    target = positional[1]
    fstype = "generic"
elseif #positional == 2 then
    source = positional[1]
    target = positional[2]
    fstype = "generic"
else
    source = positional[1]
    target = positional[2]
    fstype = positional[3]
end

-- check target exists and is a directory
local st = stat(target)
if not st then
    write(2, "mount: mount point '"..target.."' does not exist\n")
    exit(1)
end
if st.type ~= "directory" then
    write(2, "mount: '"..target.."' is not a directory\n")
    exit(1)
end

local ok, err = mount(source or "", target, fstype, flags)
if not ok then
    write(2, "mount: "..(err or "failed").."\n")
    exit(1)
end

write(1, "mounted "..target.."\n")
