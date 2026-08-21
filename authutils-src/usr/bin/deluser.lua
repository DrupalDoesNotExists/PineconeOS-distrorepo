-- deluser: remove a user account
-- Usage: deluser <username>
-- Removes entry from /etc/passwd, optionally removes home directory.
-- Requires root (uid 0).

local function usage()
    print("usage: deluser <username>")
    exit(1)
end

-- Parse args
local args = {}
for i = 1, select("#", ...) do args[i] = select(i, ...) end

if #args < 1 then usage() end

local username = args[1]

-- Require root
local myuid = getuid()
if myuid ~= 0 then
    print("deluser: must be root")
    exit(1)
end

-- Prevent deleting root
if username == "root" then
    print("deluser: cannot delete root")
    exit(1)
end

-- Read /etc/passwd
local PASSWD = "/etc/passwd"
local fd = open(PASSWD, 0)
if not fd then
    print("deluser: cannot open " .. PASSWD)
    exit(1)
end
local data = ""
while true do
    local chunk = read(fd, 65536)
    if not chunk or #chunk == 0 then break end
    data = data .. chunk
end
close(fd)

-- Parse and filter
local found = false
local home = nil
local new_lines = {}
for line in data:gmatch("[^\r\n]+") do
    local name = line:match("^([^:]+):")
    if name == username then
        found = true
        -- Extract home dir for potential cleanup
        home = line:match("([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)")
        -- home is 6th field
        _, _, _, _, _, home = line:match("([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)")
    else
        new_lines[#new_lines + 1] = line
    end
end

if not found then
    print("deluser: user '" .. username .. "' not found")
    exit(1)
end

-- Write back filtered /etc/passwd
fd = open(PASSWD, 1) -- write (truncate)
if not fd then
    print("deluser: cannot open " .. PASSWD .. " for writing")
    exit(1)
end
write(fd, table.concat(new_lines, "\n") .. "\n")
close(fd)

-- Remove home directory if it exists and is under /home/
if home and home:match("^/home/") then
    local st = stat(home)
    if st and st.type == "directory" then
        local ok, err = unlink(home)
        if not ok then
            -- Try rmdir if unlink fails on dirs
            ok, err = rmdir(home)
        end
        if not ok then
            print("deluser: warning: could not remove " .. home .. ": " .. (err or "unknown"))
        end
    end
end

print("deluser: removed user '" .. username .. "'")
