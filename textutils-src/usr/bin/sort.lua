-- sort: sort lines
-- Usage: sort [-r] [-n] [-u] [FILE...]
local function usage()
    print("usage: sort [-r] [-n] [-u] [file...]")
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

local reverse = false
local numeric = false
local unique = false
local files = {}
local i = 1

while i <= #args do
    local a = args[i]
    if a == "-r" then
        reverse = true
    elseif a == "-n" then
        numeric = true
    elseif a == "-u" then
        unique = true
    elseif a:sub(1, 1) == "-" and #a > 1 then
        -- combined flags
        for j = 2, #a do
            local c = a:sub(j, j)
            if c == "r" then reverse = true
            elseif c == "n" then numeric = true
            elseif c == "u" then unique = true
            else print("sort: unknown option: -" .. c); usage() end
        end
    else
        files[#files+1] = a
    end
    i = i + 1
end

-- Read all input
local all_lines = {}

local function add_lines(data)
    local lines = split_lines(data)
    for _, l in ipairs(lines) do
        all_lines[#all_lines+1] = l
    end
end

if #files == 0 then
    add_lines(read_all(0))
else
    for _, path in ipairs(files) do
        local fd, err = open(path, 0)
        if not fd then
            print("sort: " .. path .. ": " .. (err or "no such file"))
            exit(1)
        end
        add_lines(read_all(fd))
        close(fd)
    end
end

-- Sort
if numeric then
    table.sort(all_lines, function(a, b)
        local na, nb = tonumber(a), tonumber(b)
        if na and nb then
            if reverse then return na > nb end
            return na < nb
        end
        if reverse then return a > b end
        return a < b
    end)
else
    if reverse then
        table.sort(all_lines, function(a, b) return a > b end)
    else
        table.sort(all_lines)
    end
end

-- Unique
if unique then
    local seen = {}
    local deduped = {}
    for _, l in ipairs(all_lines) do
        if not seen[l] then
            seen[l] = true
            deduped[#deduped+1] = l
        end
    end
    all_lines = deduped
end

-- Output
for _, l in ipairs(all_lines) do
    write(1, l .. "\n")
end
