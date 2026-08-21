-- su: substitute user identity
-- Usage: su [username]
-- Switches to target user via setuid/setgid, then spawns a shell.
-- Default: switch to root. Password check for non-root callers.

local PASSWD = "/etc/passwd"

local function read_passwd()
    local fd = open(PASSWD, 0)
    if not fd then return nil end
    local data = ""
    while true do
        local chunk = read(fd, 65536)
        if not chunk or #chunk == 0 then break end
        data = data .. chunk
    end
    close(fd)
    return data
end

local function lookup_user(data, name)
    for line in data:gmatch("[^\r\n]+") do
        local uname, pass, uid, gid, gecos, home, shell = line:match(
            "([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)")
        if uname == name then
            return {
                name = uname,
                pass = pass,
                uid = tonumber(uid),
                gid = tonumber(gid),
                home = home or "/",
                shell = shell or "/usr/bin/sh.lua",
            }
        end
    end
    return nil
end

-- Parse args
local args = {}
for i = 1, select("#", ...) do args[i] = select(i, ...) end

local target = args[1] or "root"

-- Read passwd database
local data = read_passwd()
if not data then
    print("su: cannot read " .. PASSWD)
    exit(1)
end

local entry = lookup_user(data, target)
if not entry then
    print("su: unknown user '" .. target .. "'")
    exit(1)
end

-- Non-root callers must authenticate
local myuid = getuid()
if myuid ~= 0 then
    -- Check if target account is locked
    if entry.pass == "" or entry.pass == "x" then
        print("su: account '" .. target .. "' is locked")
        exit(1)
    end
    -- Simple password check (plaintext, debug kernel)
    if entry.pass ~= "x" and entry.pass ~= "" then
        print("Password for " .. target .. ":")
        -- Read password from stdin (cooked mode)
        local input = read(0, 256)
        if input then
            input = input:gsub("\r?\n$", "")
        end
        if input ~= entry.pass then
            print("su: authentication failure")
            exit(1)
        end
    end
end

-- Switch identity
if entry.gid ~= getgid() then
    local ok, err = setgid(entry.gid)
    if not ok then
        print("su: setgid failed: " .. (err or "unknown"))
        exit(1)
    end
end

if entry.uid ~= getuid() then
    local ok, err = setuid(entry.uid)
    if not ok then
        print("su: setuid failed: " .. (err or "unknown"))
        exit(1)
    end
end

-- Change to target's home directory
chdir(entry.home)

-- Spawn shell
local pid = spawn(entry.shell)
if pid then
    waitpid(pid)
end
