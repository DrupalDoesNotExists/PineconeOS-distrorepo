-- dirname: print directory component of path
-- Usage: dirname <path>
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args < 1 then
    write(2, "usage: dirname <path>\n")
    exit(1)
end

local path = args[1]

-- strip trailing slashes
while #path > 1 and path:sub(-1) == "/" do
    path = path:sub(1, -2)
end

-- find last slash
local last_slash = path:find("/[^/]*$")
if not last_slash then
    print(".")
else
    local dir = path:sub(1, last_slash - 1)
    -- strip trailing slashes from result
    while #dir > 1 and dir:sub(-1) == "/" do
        dir = dir:sub(1, -2)
    end
    print(dir)
end
