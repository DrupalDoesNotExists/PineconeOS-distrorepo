-- arp: show ARP table from /sys/net/arp
-- Usage: arp
-- Reads /sys/net/arp and displays the ARP cache.
-- Also aliased as 'arp -a' for compatibility.

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

local function usage()
    print("usage: arp [-a]")
    print("       Display ARP cache table")
    exit(1)
end

local args = {}
for i = 1, select("#", ...) do args[i] = select(i, ...) end

-- Check for -a (all) or --help
if #args > 0 and (args[1] == "-h" or args[1] == "--help") then
    usage()
end

local show_all = false
if #args > 0 and args[1] == "-a" then
    show_all = true
end

local data = read_sys("/sys/net/arp")

if not data or data == "" then
    print("arp: no ARP entries (or /sys/net/arp not available)")
    exit(0)
end

-- Parse ARP entries
-- Expected format per line: "IP HWtype HWaddress Flags Mask Iface"
-- or simplified: "ip mac flags"
print("ARP table:")
print("IP address       HW type   HW address         Flags  Iface")
print("───────────────  ────────  ─────────────────  ─────  ──────")

for line in data:gmatch("[^\n]+") do
    if show_all or not line:match("^%s*$") then
        print(line)
    end
end

exit(0)
