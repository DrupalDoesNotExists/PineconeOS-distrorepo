-- adduser: create a new user account
-- Usage: adduser <username> [uid] [gid]
-- Reads/writes /etc/passwd (name:pass:uid:gid:gecos:home:shell)
-- Requires root (uid 0).

local function usage()
    print("usage: adduser <username> [uid] [gid]")
    exit(1)
end

-- Parse args
local args = {}
for i = 1, select("#", ...) do args[i] = select(i, ...) end

if #args < 1 then usage() end

local username = args[1]
local uid = tonumber(args[2])
local gid = tonumber(args[3])

-- Require root
local myuid = getuid()
if myuid ~= 0 then
    print("adduser: must be root")
    exit(1)
end

-- Read /etc/passwd
local PASSWD = "/etc/passwd"
local fd = open(PASSWD, 0)
if not fd then
    print("adduser: cannot open " .. PASSWD)
    exit(1)
end
local data = ""
while true do
    local chunk = read(fd, 65536)
    if not chunk or #chunk == 0 then break end
    data = data .. chunk
end
close(fd)

-- Parse existing entries
local entries = {}
local max_uid = 999  -- start UIDs above 999
for line in data:gmatch("[^\r\n]+") do
    local name, pass, euid, egid = line:match("([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)")
    if name and name ~= "" then
        entries[#entries + 1] = line
        local nuid = tonumber(euid)
        if nuid and nuid > max_uid then max_uid = nuid end
    end
end

-- Check if user already exists
for _, line in ipairs(entries) do
    local name = line:match("^([^:]+):")
    if name == username then
        print("adduser: user '" .. username .. "' already exists")
        exit(1)
    end
end

-- Assign uid if not given
if not uid then
    uid = max_uid + 1
end
-- Default gid = uid
if not gid then
    gid = uid
end

local home = "/home/" .. username
local shell = "/usr/bin/sh.lua"
local gecos = username

-- Build passwd line: name:pass:uid:gid:gecos:home:shell
-- Password is "x" (locked) by default — user must set via passwd or su
local newline = username .. ":x:" .. uid .. ":" .. gid .. ":" .. gecos .. ":" .. home .. ":" .. shell

-- Append to /etc/passwd
fd = open(PASSWD, 1) -- write
if not fd then
    print("adduser: cannot open " .. PASSWD .. " for writing")
    exit(1)
end
-- If existing data, ensure trailing newline
if #data > 0 and data:sub(-1) ~= "\n" then
    write(fd, "\n")
end
write(fd, newline .. "\n")
close(fd)

-- Create home directory
mkdir(home, 493) -- 0755

-- Try to chown home directory
local ok, err = chown(home, uid, gid)
if not ok then
    print("adduser: warning: chown " .. home .. " failed: " .. (err or "unknown"))
end

print("adduser: created user '" .. username .. "' (uid=" .. uid .. " gid=" .. gid .. ")")
