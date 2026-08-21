-- chmod: change file mode
-- Usage: chmod <mode> <path...>
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args < 2 then
    write(2, "usage: chmod <mode> <file...>\n")
    exit(1)
end

local mode_str = args[1]
local mode = tonumber(mode_str, 8)
if not mode then
    -- try decimal
    mode = tonumber(mode_str)
end
if not mode then
    write(2, "chmod: invalid mode: '"..mode_str.."'\n")
    exit(1)
end

for i=2,#args do
    local path = args[i]
    local ok, err = chmod(path, mode)
    if not ok then
        write(2, "chmod: cannot change mode of '"..path.."': "..(err or "failed").."\n")
        exit(1)
    end
end
