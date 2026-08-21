-- rmdir: remove empty directory
-- Usage: rmdir <path...>
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args == 0 then
    write(2, "usage: rmdir <directory...>\n")
    exit(1)
end

for _, path in ipairs(args) do
    local st = stat(path)
    if not st then
        write(2, "rmdir: failed to remove '"..path.."': No such file or directory\n")
        exit(1)
    end
    if st.type ~= "dir" then
        write(2, "rmdir: failed to remove '"..path.."': Not a directory\n")
        exit(1)
    end
    local ok, err = rmdir(path)
    if not ok then
        write(2, "rmdir: failed to remove '"..path.."': "..(err or "directory not empty").."\n")
        exit(1)
    end
end
