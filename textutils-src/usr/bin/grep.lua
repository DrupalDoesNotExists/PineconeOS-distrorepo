-- grep: search patterns in files/stdin
-- Usage: grep [-i] [-v] [-n] [-r] PATTERN [FILE...]
local function usage()
    print("usage: grep [-i] [-v] [-n] [-r] PATTERN [FILE...]")
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

local function is_dir(path)
    local s = stat(path)
    if s and s.type == "dir" then return true end
    return false
end

local function list_files_recursive(base)
    local files = {}
    local function walk(dir)
        local fd = open(dir, 0)
        if not fd then return end
        -- Try reading directory contents; if stat says dir, iterate
        -- Use a simple approach: read dir as file, parse names
        -- Actually in CC:Tweaked/KNUCK we list by trying known children
        -- Since we can't readdir natively, we'll grep files passed as args
        -- For -r, we try to read the path and split into lines (directory listing)
        close(fd)
    end
    -- Simpler: just return the path itself if it's a file
    files[#files+1] = base
    return files
end

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

-- Parse options
local case_insensitive = false
local invert = false
local show_line_numbers = false
local recursive = false
local i = 1

while i <= #args do
    local a = args[i]
    if a == "-i" then
        case_insensitive = true
    elseif a == "-v" then
        invert = true
    elseif a == "-n" then
        show_line_numbers = true
    elseif a == "-r" then
        recursive = true
    elseif a:sub(1, 1) == "-" and #a > 1 then
        -- combined flags like -inv
        for j = 2, #a do
            local c = a:sub(j, j)
            if c == "i" then case_insensitive = true
            elseif c == "v" then invert = true
            elseif c == "n" then show_line_numbers = true
            elseif c == "r" then recursive = true
            else print("grep: unknown option: -" .. c); usage() end
        end
    else
        break
    end
    i = i + 1
end

if i > #args then usage() end
local pattern = args[i]
i = i + 1

-- Collect files
local files = {}
while i <= #args do
    files[#files+1] = args[i]
    i = i + 1
end

-- If recursive, expand directories
if recursive and #files > 0 then
    local expanded = {}
    for _, f in ipairs(files) do
        if is_dir(f) then
            -- For recursive, try to read the dir as a file listing
            -- In KNUCK, directories may not be readable, so we try anyway
            local dir_data = read_all(open(f, 0) or 0)
            -- If we got data, split by newlines for child names
            if dir_data and #dir_data > 0 then
                for _, name in ipairs(split_lines(dir_data)) do
                    if name ~= "" then
                        local child = f .. "/" .. name
                        expanded[#expanded+1] = child
                    end
                end
            end
        else
            expanded[#expanded+1] = f
        end
    end
    files = expanded
end

local found_any = false

local function grep_file(path, fd)
    local data = read_all(fd)
    local lines = split_lines(data)
    for line_num, line in ipairs(lines) do
        local haystack = case_insensitive and line:lower() or line
        local needle = case_insensitive and pattern:lower() or pattern
        -- Try plain match first, then Lua pattern
        local matched = false
        local ok, result = pcall(string.find, haystack, needle, 1, true)
        if ok and result then
            matched = true
        else
            ok, result = pcall(string.find, haystack, needle)
            if ok and result then
                matched = true
            end
        end
        if invert then matched = not matched end
        if matched then
            found_any = true
            local out = ""
            if show_line_numbers then
                out = line_num .. ":"
            end
            out = out .. line .. "\n"
            write(1, out)
        end
    end
end

if #files == 0 then
    -- Read stdin
    grep_file("-", 0)
else
    for _, path in ipairs(files) do
        local fd, err = open(path, 0)
        if not fd then
            print("grep: " .. path .. ": " .. (err or "no such file"))
        else
            grep_file(path, fd)
            close(fd)
        end
    end
end

exit(found_any and 0 or 1)
