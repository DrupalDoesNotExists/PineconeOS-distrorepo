-- find: recursively list files
-- Usage: find <path> [path...]
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args == 0 then
    args[1] = "."
end

local function find_recursive(path)
    -- print current entry
    print(path)

    local st = stat(path)
    if not st then return end

    if st.type == "dir" then
        local entries = readdir(path)
        if entries then
            table.sort(entries, function(a,b) return a.name < b.name end)
            for _, e in ipairs(entries) do
                if e.name ~= "." and e.name ~= ".." then
                    local child = path .. "/" .. e.name
                    find_recursive(child)
                end
            end
        end
    end
end

for _, p in ipairs(args) do
    find_recursive(p)
end
