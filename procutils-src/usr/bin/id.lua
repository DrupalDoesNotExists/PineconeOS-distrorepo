-- id: print real and effective user and group IDs
-- Usage: id [user]
-- Without arguments, prints current uid/gid.
-- With a username argument, looks up via getpwnam().
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args > 0 then
    -- Look up the named user
    for _, name in ipairs(args) do
        local entry = getpwnam(name)
        if entry then
            write(1, string.format("uid=%d(%s) gid=%d(%s)\n",
                entry.uid, name, entry.gid, name))
        else
            write(2, "id: '" .. name .. "': no such user\n")
            exit(1)
        end
    end
else
    local uid = getuid()
    local euid = geteuid()
    local gid = getgid()
    local egid = getegid()

    -- Look up names
    local function lookup_name(tbl, id)
        local e = tbl(id)
        if e and e.name then return e.name end
        return tostring(id)
    end

    local uname = lookup_name(getpwuid, uid)
    local euname = lookup_name(getpwuid, euid)

    local out = string.format("uid=%d(%s) gid=%d(%s)",
        uid, uname, gid, lookup_name(getgrgid, gid))

    if euid ~= uid then
        out = out .. string.format(" euid=%d(%s)", euid, euname)
    end
    if egid ~= gid then
        out = out .. string.format(" egid=%d(%s)", egid, lookup_name(getgrgid, egid))
    end

    write(1, out .. "\n")
end
