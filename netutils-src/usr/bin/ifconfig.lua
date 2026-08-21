-- ifconfig: show network interface configuration
-- Usage: ifconfig [interface]

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

local function read_sys_lines(path)
    local s = read_sys(path)
    if not s or s == "" then return {} end
    local lines = {}
    for line in s:gmatch("[^\n]+") do
        lines[#lines+1] = line
    end
    return lines
end

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

-- Check if network info is available
local ip = read_sys("/sys/net/ip")
if ip == nil or ip == "" then
    print("ifconfig: no interface information available in this KNUCK build")
    exit(0)
end

local gw = read_sys("/sys/net/gateway") or "0.0.0.0"
local nm = read_sys("/sys/net/netmask") or "255.255.255.0"
local ch = read_sys("/sys/net/channel") or "0"

print("modem0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>")
print("        inet addr:" .. ip .. "  Mask:" .. nm)
print("        inet addr:" .. gw .. "  Gateway")
print("        channel " .. ch)

-- ARP table
local arp_lines = read_sys_lines("/sys/net/arp")
if #arp_lines > 0 then
    print("  ARP table:")
    for _, line in ipairs(arp_lines) do
        print("    " .. line)
    end
end

exit(0)
