-- cut: cut fields by delimiter
-- Usage: cut -d DELIM -f FIELDS [FILE]
local function usage()
    print("usage: cut -d DELIM -f FIELDS [file]")
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
            lines[#lines+1] = data:sub(pos, nl - 1)
            pos = nl + 1
        else
            if pos <= #data then
                lines[#lines+1] = data:sub(pos)
            end
            break
        end
    end
    return lines
end

local function parse_fields(spec)
    local fields = {}
    for part in spec:gmatch("[^,]+") do
        local dash = part:find("-", 1, true)
        if dash then
            local from = tonumber(part:sub(1, dash - 1))
            local to = tonumber(part:sub(dash + 1))
            if from and to then
                for n = from, to do
                    fields[#fields+1] = n
                end
            end
        else
            local n = tonumber(part)
            if n then
                fields[#fields+1] = n
            end
        end
    end
    return fields
end

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

local delim = nil
local field_spec = nil
local files = {}
local i = 1

while i <= #args do
    local a = args[i]
    if a == "-d" then
        i = i + 1
        if i > #args then
            print("cut: -d requires an argument")
            usage()
        end
        delim = args[i]
    elseif a:sub(1, 2) == "-d" and #a > 2 then
        delim = a:sub(3)
    elseif a == "-f" then
        i = i + 1
        if i > #args then
            print("cut: -f requires an argument")
            usage()
        end
        field_spec = args[i]
    elseif a:sub(1, 2) == "-f" and #a > 2 then
        field_spec = a:sub(3)
    elseif a == "-h" or a == "--help" then
        usage()
    else
        files[#files+1] = a
    end
    i = i + 1
end

if not delim then
    print("cut: -d delimiter is required")
    usage()
end
if not field_spec then
    print("cut: -f fields is required")
    usage()
end

local fields = parse_fields(field_spec)

local function process(fd)
    local data = read_all(fd)
    local lines = split_lines(data)
    for _, line in ipairs(lines) do
        local parts = {}
        local pos = 1
        while true do
            local dp = line:find(delim, pos, true)
            if dp then
                parts[#parts+1] = line:sub(pos, dp - 1)
                pos = dp + #delim
            else
                parts[#parts+1] = line:sub(pos)
                break
            end
        end
        local out = {}
        for _, f in ipairs(fields) do
            if f <= #parts then
                out[#out+1] = parts[f]
            end
        end
        write(1, table.concat(out, delim) .. "\n")
    end
end

if #files == 0 then
    process(0)
else
    for _, path in ipairs(files) do
        local fd, err = open(path, 0)
        if not fd then
            print("cut: " .. path .. ": " .. (err or "no such file"))
            exit(1)
        end
        process(fd)
        close(fd)
    end
end
