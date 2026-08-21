-- sed: stream editor
-- Usage: sed [-n] 's/FIND/REPL/[g]' [FILE...]
--        sed [-n] 'NUMp' [FILE...]
local function usage()
    print("usage: sed [-n] 's/find/replace/[g]' [file...]")
    print("       sed [-n] 'NUMp' [file...]")
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

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

local suppress_default = false
local expressions = {}
local files = {}
local i = 1

-- Parse -n flag
while i <= #args do
    local a = args[i]
    if a == "-n" then
        suppress_default = true
    elseif a:sub(1, 1) == "-" and #a > 1 and a ~= "-" then
        -- Could be combined flags but sed typically only has -n
        print("sed: unknown option: " .. a)
        usage()
    else
        break
    end
    i = i + 1
end

-- Next arg(s) are expressions or files
-- If arg matches 's/...' or NUMp, it's an expression; otherwise a file
while i <= #args do
    local a = args[i]
    if a:match("^s/.*/") then
        -- s/ command
        local delim = a:sub(2, 2)
        local rest = a:sub(3)
        local p1 = rest:find(delim, 1, true)
        if not p1 then print("sed: bad expression: " .. a); usage() end
        local find = rest:sub(1, p1 - 1)
        local rest2 = rest:sub(p1 + 1)
        local p2 = rest2:find(delim, 1, true)
        if not p2 then print("sed: bad expression: " .. a); usage() end
        local repl = rest2:sub(1, p2 - 1)
        local flags = rest2:sub(p2 + 1)
        local global = false
        if flags:find("g") then global = true end
        expressions[#expressions+1] = { type = "s", find = find, repl = repl, global = global }
    elseif a:match("^%d+p$") then
        local num = tonumber(a:match("^(%d+)p$"))
        expressions[#expressions+1] = { type = "p", line = num }
    else
        files[#files+1] = a
    end
    i = i + 1
end

if #expressions == 0 then
    print("sed: no expression")
    usage()
end

local function process(fd)
    local data = read_all(fd)
    local lines = split_lines(data)
    for line_num, line in ipairs(lines) do
        local output = nil
        local matched = false
        for _, expr in ipairs(expressions) do
            if expr.type == "s" then
                local count = expr.global and math.huge or 1
                local new_line, n = line:gsub(expr.find, expr.repl, count)
                if n > 0 then
                    output = new_line
                    matched = true
                end
            elseif expr.type == "p" then
                if line_num == expr.line then
                    output = line
                    matched = true
                end
            end
        end
        if matched and output then
            write(1, output .. "\n")
        elseif not suppress_default and not matched then
            -- Default: print line if not -n, or if no match in s/// with -n
            -- With -n, only explicit matches print
            if not suppress_default then
                write(1, line .. "\n")
            end
        end
    end
end

if #files == 0 then
    process(0)
else
    for _, path in ipairs(files) do
        local fd, err = open(path, 0)
        if not fd then
            print("sed: " .. path .. ": " .. (err or "no such file"))
        else
            process(fd)
            close(fd)
        end
    end
end
