-- tr: translate or delete characters
-- Usage: tr SET1 [SET2]
--        tr -d SET1
local function usage()
    print("usage: tr SET1 [SET2]")
    print("       tr -d SET")
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

local function expand_set(s)
    local chars = {}
    local i = 1
    while i <= #s do
        local c = s:sub(i, i)
        if c == "\\" and i < #s then
            -- escape sequence
            local next_c = s:sub(i+1, i+1)
            if next_c == "n" then chars[#chars+1] = "\n"
            elseif next_c == "t" then chars[#chars+1] = "\t"
            elseif next_c == "\\" then chars[#chars+1] = "\\"
            else chars[#chars+1] = next_c end
            i = i + 2
        elseif c == "-" and #chars > 0 and i < #s then
            -- range like a-z
            local from = chars[#chars]
            local to = s:sub(i+1, i+1)
            if from and to and #from == 1 and #to == 1 then
                -- remove the last char (it's the start of range)
                chars[#chars] = nil
                local f_byte = string.byte(from)
                local t_byte = string.byte(to)
                if f_byte <= t_byte then
                    for b = f_byte, t_byte do
                        chars[#chars+1] = string.char(b)
                    end
                else
                    for b = f_byte, t_byte, -1 do
                        chars[#chars+1] = string.char(b)
                    end
                end
                i = i + 2
            else
                chars[#chars+1] = c
                i = i + 1
            end
        else
            chars[#chars+1] = c
            i = i + 1
        end
    end
    return chars
end

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

local delete_mode = false
local set1, set2
local i = 1

while i <= #args do
    local a = args[i]
    if a == "-d" then
        delete_mode = true
    elseif a == "-h" or a == "--help" then
        usage()
    elseif not set1 then
        set1 = a
    elseif not set2 then
        set2 = a
    end
    i = i + 1
end

if not set1 then
    print("tr: missing SET1")
    usage()
end

local chars1 = expand_set(set1)

if delete_mode then
    -- delete mode: build set of chars to delete
    local delete_set = {}
    for _, c in ipairs(chars1) do
        delete_set[c] = true
    end
    local data = read_all(0)
    local out = {}
    for j = 1, #data do
        local c = data:sub(j, j)
        if not delete_set[c] then
            out[#out+1] = c
        end
    end
    write(1, table.concat(out))
elseif set2 then
    -- translate mode
    local chars2 = expand_set(set2)
    local map = {}
    for j = 1, #chars1 do
        if j <= #chars2 then
            map[chars1[j]] = chars2[j]
        else
            -- SET2 shorter: last char repeats
            map[chars1[j]] = chars2[#chars2]
        end
    end
    local data = read_all(0)
    local out = {}
    for j = 1, #data do
        local c = data:sub(j, j)
        out[#out+1] = map[c] or c
    end
    write(1, table.concat(out))
else
    print("tr: missing SET2 (or use -d SET1)")
    usage()
end
