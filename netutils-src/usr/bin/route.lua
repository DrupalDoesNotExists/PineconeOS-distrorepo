-- route: show/manipulate the IP routing table
-- Usage: route [-n]
--        route add -net <dest> netmask <mask> gw <gw>
--        route del -net <dest> netmask <mask> gw <gw>

local function read_sys(path)
    local fd = open(path, "r")
    if not fd then return nil end
    local chunks = {}
    while true do
        local data = read(fd, 4096)
        if not data or #data == 0 then break end
        chunks[#chunks+1] = data
    end
    close(fd)
    local s = table.concat(chunks)
    return s:gsub("%s+$", "")
end

local function write_sys(path, value)
    local fd = open(path, "w")
    if not fd then return false, "cannot open " .. path .. " for writing" end
    write(fd, value .. "\n")
    close(fd)
    return true
end

local function usage()
    print("usage: route [-n]")
    print("       route add -net dest netmask mask gw gateway")
    print("       route del -net dest netmask mask gw gateway")
    exit(1)
end

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args < 1 then
    -- show routes
    local routes = read_sys("/sys/net/routes")
    if not routes or routes == "" then
        print("route: no routing information available")
        exit(0)
    end
    print("Kernel IP routing table")
    print("Destination     Gateway         Mask            Metric")
    for line in routes:gmatch("[^\n]+") do
        print(line)
    end
    exit(0)
end

local cmd = args[1]

if cmd == "-n" then
    local routes = read_sys("/sys/net/routes")
    if not routes or routes == "" then
        print("route: no routing information available")
        exit(0)
    end
    print("Kernel IP routing table")
    print("Destination     Gateway         Mask            Metric")
    for line in routes:gmatch("[^\n]+") do
        print(line)
    end
    exit(0)
elseif cmd == "add" then
    -- route add -net dest netmask mask gw gateway
    local dest, mask, gw
    local i = 2
    while i <= #args do
        local a = args[i]
        if a == "-net" then
            i = i + 1
            dest = args[i]
        elseif a == "netmask" then
            i = i + 1
            mask = args[i]
        elseif a == "gw" then
            i = i + 1
            gw = args[i]
        end
        i = i + 1
    end
    if not dest or not mask or not gw then
        print("route: add requires -net dest netmask mask gw gateway")
        usage()
    end
    local route_str = dest .. " " .. mask .. " " .. gw
    local ok, err = write_sys("/sys/net/routes", route_str)
    if not ok then
        print("route: " .. tostring(err))
        exit(1)
    end
    print("route: added " .. dest .. "/" .. mask .. " via " .. gw)
    exit(0)
elseif cmd == "del" then
    local dest, mask, gw
    local i = 2
    while i <= #args do
        local a = args[i]
        if a == "-net" then
            i = i + 1
            dest = args[i]
        elseif a == "netmask" then
            i = i + 1
            mask = args[i]
        elseif a == "gw" then
            i = i + 1
            gw = args[i]
        end
        i = i + 1
    end
    if not dest or not mask or not gw then
        print("route: del requires -net dest netmask mask gw gateway")
        usage()
    end
    local route_str = "del " .. dest .. " " .. mask .. " " .. gw
    local ok, err = write_sys("/sys/net/routes", route_str)
    if not ok then
        print("route: " .. tostring(err))
        exit(1)
    end
    print("route: deleted " .. dest .. "/" .. mask .. " via " .. gw)
    exit(0)
else
    usage()
end
