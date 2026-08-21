-- nc: netcat - connect to host:port and relay stdin/stdout
-- Usage: nc host port
-- Uses KNUCK AF_MODEM TCP sockets.

local function usage()
    print("usage: nc host port")
    exit(1)
end

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args < 2 then
    usage()
end

local host = args[1]
local port = tonumber(args[2])
if not port or port < 1 or port > 65535 then
    print("nc: invalid port: " .. tostring(args[2]))
    exit(1)
end

-- Create TCP socket
local fd, err = socket("modem", "stream", 6)
if not fd then
    print("nc: socket creation failed: " .. tostring(err))
    exit(1)
end

-- Connect to remote host:port
local target = host .. ":" .. port
local ok, cerr = connect(fd, target)
if not ok then
    print("nc: connect failed: " .. tostring(cerr))
    close(fd)
    exit(1)
end

print("nc: connected to " .. target)

-- Set a short receive timeout so we can check stdin periodically
setsockopt(fd, 1, 20, 0.5)

-- Relay loop: read stdin -> send to socket, read socket -> write stdout
while true do
    -- Read from stdin (non-blocking check via poll)
    local stdin_data = read(0, 4096)
    if stdin_data and #stdin_data > 0 then
        local sent, serr = send(fd, stdin_data)
        if not sent then
            print("nc: send error: " .. tostring(serr))
            break
        end
    end

    -- Read from socket (non-blocking with timeout)
    local data, rerr = recv(fd, 4096)
    if data and #data > 0 then
        write(1, data)
    elseif data == nil and rerr ~= "timeout" then
        -- Connection closed or real error
        break
    end

    -- If stdin returned empty data, stdin is closed
    if stdin_data == nil or #stdin_data == 0 then
        -- Give a moment for remaining data
        shutdown(fd, "write")
        -- Drain remaining socket data
        while true do
            local d = recv(fd, 4096)
            if d and #d > 0 then
                write(1, d)
            else
                break
            end
        end
        break
    end
end

close(fd)
exit(0)
