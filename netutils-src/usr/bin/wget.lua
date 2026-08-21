-- wget: fetch a URL via HTTP
-- Usage: wget [-O file] URL
-- Uses KNUCK AF_HTTP socket (http.get wrapped in socket API).

local function read_all(fd)
    local chunks = {}
    while true do
        local data = read(fd, 65536)
        if not data or #data == 0 then break end
        chunks[#chunks+1] = data
    end
    return table.concat(chunks)
end

local function usage()
    print("usage: wget [-O file] URL")
    exit(1)
end

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

-- Parse arguments
local outfile = nil
local url = nil
local i = 1
while i <= #args do
    local a = args[i]
    if a == "-O" then
        i = i + 1
        if i > #args then
            print("wget: missing argument for -O")
            usage()
        end
        outfile = args[i]
    elseif a == "-O" and #a > 2 then
        outfile = a:sub(3)
    elseif a == "--help" or a == "-h" then
        usage()
    elseif a:sub(1,1) == "-" and #a > 1 then
        print("wget: unknown option: " .. a)
        usage()
    else
        url = a
    end
    i = i + 1
end

if not url then
    print("wget: missing URL")
    usage()
end

-- Validate URL
if not url:match("^https?://") then
    print("wget: invalid URL (must start with http:// or https://)")
    exit(1)
end

-- Create HTTP socket
local fd, err = socket("http", "stream", 0)
if not fd then
    print("wget: socket creation failed: " .. tostring(err))
    exit(1)
end

-- Connect to URL
local ok, cerr = connect(fd, url)
if not ok then
    print("wget: connection failed: " .. tostring(cerr))
    close(fd)
    exit(1)
end

-- Send request (HTTP socket handles this via the send call)
local ok, serr = send(fd, "")
if not ok and serr ~= nil then
    print("wget: send failed: " .. tostring(serr))
    close(fd)
    exit(1)
end

-- Receive response body
local body, rerr = recv(fd, 65536)
close(fd)

if not body then
    print("wget: recv failed: " .. tostring(rerr))
    exit(1)
end

-- Write output
if outfile then
    local ofd = open(outfile, "w")
    if not ofd then
        print("wget: cannot open '" .. outfile .. "' for writing")
        exit(1)
    end
    write(ofd, body)
    close(ofd)
    print("wget: saved to " .. outfile .. " (" .. #body .. " bytes)")
else
    -- Write to stdout
    write(1, body)
end

exit(0)
