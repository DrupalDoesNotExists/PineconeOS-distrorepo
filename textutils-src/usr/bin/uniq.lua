-- uniq: filter adjacent duplicate lines
-- Usage: uniq [FILE]
local function usage()
    print("usage: uniq [file]")
    exit(1)
end

local function read_all(fd)
    local chunks = {}
    while true do
        local data = read(fd, 65536)
        if not data or #data == 0 then break end
        chunks[#chunks+1] = data
    end
    return table.concat(chunks)
end

local function split_lines(data)
    local lines = {}
    local pos = 1
    while pos <= #data do
        local nl = data:find("\n", pos, true)
        if nl then
            local l = data:sub(pos, nl - 1)
            if #l > 0 then
                lines[#lines+1] = l
            end
            pos = nl + 1
        else
            if pos <= #data then
                local l = data:sub(pos)
                if #l > 0 then
                    lines[#lines+1] = l
                end
            end
            break
        end
    end
    return lines
end

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

local file = nil
for _, a in ipairs(args) do
    if a == "-h" or a == "--help" then
        usage()
    else
        file = a
    end
end

local data
if file then
    local fd, err = open(file, 0)
    if not fd then
        print("uniq: " .. file .. ": " .. (err or "no such file"))
        exit(1)
    end
    data = read_all(fd)
    close(fd)
else
    data = read_all(0)
end

local lines = split_lines(data)
local prev = nil
for _, line in ipairs(lines) do
    if line ~= prev then
        write(1, line .. "\n")
        prev = line
    end
end
