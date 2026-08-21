-- ip: show/configure network interfaces
-- Usage: ip addr show
--        ip route show
--        ip addr set <ip> <mask>
--        ip route add <dest> <mask> <gw>
--        ip route del <dest> <mask> <gw>
-- Uses /sys/net/* filesystem interface.

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
    print("usage: ip addr show")
    print("       ip addr set <ip> <mask>")
    print("       ip route show")
    print("       ip route add <dest> <mask> <gw>")
    print("       ip route del <dest> <mask> <gw>")
    exit(1)
end

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args < 1 then usage() end

local cmd = args[1]

if cmd == "addr" then
    local sub = args[2] or "show"
    if sub == "show" then
        local ip_addr = read_sys("/sys/net/ip")
        local gw = read_sys("/sys/net/gateway")
        local nm = read_sys("/sys/net/netmask")
        local ch = read_sys("/sys/net/channel")
        if not ip_addr then
            print("ip: no network interface available")
            exit(1)
        end
        print("modem0: <BROADCAST,RUNNING,UP>")
        print("        inet " .. (ip_addr or "0.0.0.0") .. "/" .. (nm or "255.255.255.0"))
        print("        gateway " .. (gw or "0.0.0.0"))
        print("        channel " .. (ch or "0"))
    elseif sub == "set" then
        local new_ip = args[3]
        local new_mask = args[4]
        if not new_ip then
            print("ip: missing IP address")
            usage()
        end
        local ok, err = write_sys("/sys/net/ip", new_ip)
        if not ok then
            print("ip: " .. tostring(err))
            exit(1)
        end
        if new_mask then
            local ok2, err2 = write_sys("/sys/net/netmask", new_mask)
            if not ok2 then
                print("ip: " .. tostring(err2))
                exit(1)
            end
        end
        print("ip: interface configured")
    else
        usage()
    end
elseif cmd == "route" then
    local sub = args[2] or "show"
    if sub == "show" then
        local routes = read_sys("/sys/net/routes")
        if not routes or routes == "" then
            print("ip: no routes available")
        else
            print("Kernel IP routing table")
            print("Destination     Gateway         Mask            Metric")
            for line in routes:gmatch("[^\n]+") do
                print(line)
            end
        end
    elseif sub == "add" then
        local dest = args[3]
        local mask = args[4]
        local gw = args[5]
        if not dest or not mask or not gw then
            print("ip: route add requires dest mask gw")
            usage()
        end
        -- Write route as "dest mask gw" to /sys/net/routes
        local route_str = dest .. " " .. mask .. " " .. gw
        local ok, err = write_sys("/sys/net/routes", route_str)
        if not ok then
            print("ip: " .. tostring(err))
            exit(1)
        end
        print("ip: route added")
    elseif sub == "del" then
        local dest = args[3]
        local mask = args[4]
        local gw = args[5]
        if not dest or not mask or not gw then
            print("ip: route del requires dest mask gw")
            usage()
        end
        -- Write delete route as "del dest mask gw"
        local route_str = "del " .. dest .. " " .. mask .. " " .. gw
        local ok, err = write_sys("/sys/net/routes", route_str)
        if not ok then
            print("ip: " .. tostring(err))
            exit(1)
        end
        print("ip: route deleted")
    else
        usage()
    end
else
    usage()
end

exit(0)
