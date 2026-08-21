-- basename: strip directory from path
-- Usage: basename <path> [suffix]
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args < 1 then
    write(2, "usage: basename <path> [suffix]\n")
    exit(1)
end

local path = args[1]
local suffix = args[2]

-- strip trailing slashes
while #path > 1 and path:sub(-1) == "/" do
    path = path:sub(1, -2)
end

-- extract basename
local name = path
local slash = path:find("/[^/]*$")
if slash then
    name = path:sub(slash + 1)
end

-- strip suffix if provided
if suffix and #suffix > 0 and name:sub(-#suffix) == suffix then
    name = name:sub(1, -(#suffix + 1))
end

print(name)
