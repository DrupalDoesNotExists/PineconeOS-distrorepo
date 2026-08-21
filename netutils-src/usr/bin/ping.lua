-- ping: send ICMP echo requests and measure RTT
-- Usage: ping [-c count] [-i interval] host
-- Uses AF_ICMP socket for real ICMP echo requests/replies.

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

-- bxor via pure arithmetic (no bit32 in sandbox)
local function bxor(a, b)
  local r, bit = 0, 1
  while a > 0 or b > 0 do
    local abit, bbit = a % 2, b % 2
    if abit ~= bbit then r = r + bit end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
    bit = bit * 2
  end
  return r
end

-- Parse arguments
local count = nil       -- -c count: stop after count replies
local interval = 1.0    -- -i interval: seconds between pings
local host = nil

local i = 1
while i <= #args do
  local a = args[i]
  if a == "-c" and i < #args then
    count = tonumber(args[i+1])
    if not count or count < 1 then
      print("ping: invalid count")
      exit(1)
    end
    i = i + 2
  elseif a == "-i" and i < #args then
    interval = tonumber(args[i+1])
    if not interval or interval < 0.1 then
      print("ping: invalid interval")
      exit(1)
    end
    i = i + 2
  elseif a:sub(1,2) == "-c" then
    count = tonumber(a:sub(3))
    if not count or count < 1 then
      print("ping: invalid count")
      exit(1)
    end
    i = i + 1
  elseif a:sub(1,2) == "-i" then
    interval = tonumber(a:sub(3))
    if not interval or interval < 0.1 then
      print("ping: invalid interval")
      exit(1)
    end
    i = i + 1
  elseif a == "-h" or a == "--help" then
    print("usage: ping [-c count] [-i interval] host")
    exit(0)
  elseif a:sub(1,1) == "-" then
    print("ping: unknown option: " .. a)
    exit(1)
  else
    host = a
    i = i + 1
  end
end

if not host then
  print("usage: ping [-c count] [-i interval] host")
  exit(1)
end

-- Resolve host to IP (try /etc/hosts first, then treat as IP)
local dest_ip = nil
local function resolve_host(name)
  -- Check /etc/hosts
  local fd = open("/etc/hosts", 0)
  if fd then
    local data = ""
    while true do
      local chunk = read(fd, 4096)
      if not chunk or #chunk == 0 then break end
      data = data .. chunk
    end
    close(fd)
    for line in data:gmatch("[^\n]+") do
      if not line:match("^#") then
        local ip, hostnames = line:match("^(%d+%.%d+%.%d+%.%d+)%s+(.+)$")
        if ip then
          for h in hostnames:gmatch("%S+") do
            if h == name then return ip end
          end
        end
      end
    end
  end
  -- Treat as literal IP
  if name:match("^%d+%.%d+%.%d+%.%d+$") then
    return name
  end
  return nil
end

dest_ip = resolve_host(host)
if not dest_ip then
  print("ping: unknown host " .. host)
  exit(1)
end

-- Create ICMP socket
local fd = socket("icmp", "dgram", 1)
if not fd then
  print("ping: failed to create ICMP socket")
  exit(1)
end

-- Bind to receive all ICMP
local ok, err = bind(fd, "0.0.0.0")
if not ok then
  print("ping: bind failed: " .. (err or "unknown"))
  exit(1)
end

-- ICMP echo request helpers
local function build_echo(ident, seq, payload)
  -- type=8 (echo request), code=0, checksum=0 (computed later), ident, seq
  local header = string.char(8, 0, 0, 0,
    math.floor(ident / 256), ident % 256,
    math.floor(seq / 256), seq % 256)
  local data = header .. payload
  -- Compute ICMP checksum
  local sum = 0
  for i = 1, #data, 2 do
    local hi = data:byte(i) or 0
    local lo = data:byte(i + 1) or 0
    sum = sum + hi * 256 + lo
  end
  while sum > 0xFFFF do
    sum = (sum % 0x10000) + math.floor(sum / 0x10000)
  end
  local cs = bxor(sum, 0xFFFF)
  return string.char(8, 0, math.floor(cs / 256), cs % 256,
    math.floor(ident / 256), ident % 256,
    math.floor(seq / 256), seq % 256) .. payload
end

local function parse_icmp(data)
  if #data < 8 then return nil end
  local typ = data:byte(1)
  local code = data:byte(2)
  local ident = data:byte(5) * 256 + data:byte(6)
  local seq = data:byte(7) * 256 + data:byte(8)
  return typ, code, ident, seq
end

-- Generate a timestamp payload (8 bytes: seconds since boot as float approximation)
local function make_payload()
  local t = os.clock()
  local sec = math.floor(t)
  local usec = math.floor((t - sec) * 1000000)
  return string.char(
    math.floor(sec / 256) % 256, sec % 256,
    math.floor(usec / 256) % 256, usec % 256,
    0, 0, 0, 0)
end

-- Main ping loop
local ident = math.random(1, 65535)
local seq = 0
local sent = 0
local received = 0
local min_rtt = nil
local max_rtt = nil
local sum_rtt = 0

print("PING " .. host .. " (" .. dest_ip .. ") 56(84) bytes of data.")

while true do
  if count and sent >= count then break end

  -- Build and send echo request
  seq = seq + 1
  local payload = make_payload()
  local pkt = build_echo(ident, seq, payload)
  local send_time = os.clock()

  local ok, err = sendto(fd, pkt, dest_ip, 0)
  if not ok then
    print("ping: sendto failed: " .. (err or "unknown"))
    break
  end
  sent = sent + 1

  -- Wait for reply (with timeout)
  local reply = nil
  local reply_ip = nil
  local deadline = os.clock() + 2.0  -- 2 second timeout

  while os.clock() < deadline do
    reply, reply_ip = recvfrom(fd)
    if reply then
      local rtyp, rcode, rident, rseq = parse_icmp(reply)
      if rtyp == 0 and rident == ident and rseq == seq then
        break
      end
      -- Not our reply, keep waiting
      reply = nil
    end
  end

  local rtt = (os.clock() - send_time) * 1000  -- ms

  if reply then
    received = received + 1
    sum_rtt = sum_rtt + rtt
    if not min_rtt or rtt < min_rtt then min_rtt = rtt end
    if not max_rtt or rtt > max_rtt then max_rtt = rtt end
    print(#reply .. " bytes from " .. (reply_ip or dest_ip) ..
          ": icmp_seq=" .. seq .. " ttl=64 time=" ..
          string.format("%.3f", rtt) .. " ms")
  else
    print("Request timeout for icmp_seq " .. seq)
  end

  -- Wait for interval between pings
  if not count or sent < count then
    local wait_until = os.clock() + interval
    while os.clock() < wait_until do
      -- Small sleep to avoid busy-waiting
      sleep(0.05)
    end
  end
end

-- Print statistics
print("")
print("--- " .. host .. " ping statistics ---")
local loss = 0
if sent > 0 then
  loss = math.floor((1 - received / sent) * 100 + 0.5)
end
print(sent .. " packets transmitted, " .. received .. " received, " ..
      loss .. "% packet loss")

if received > 0 then
  local avg = sum_rtt / received
  print("rtt min/avg/max = " ..
        string.format("%.3f", min_rtt) .. "/" ..
        string.format("%.3f", avg) .. "/" ..
        string.format("%.3f", max_rtt) .. " ms")
end

close(fd)
exit(0)
