-- touch: create empty file or update mtime
-- Usage: touch <file...>
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args == 0 then
    write(2, "touch: missing operand\n")
    exit(1)
end

for _, path in ipairs(args) do
    local st = stat(path)
    if st then
        -- file exists: reopen to update mtime
        local fd = open(path, "a")
        if fd then
            write(fd, "")
            close(fd)
        else
            write(2, "touch: cannot touch '"..path.."'\n")
            exit(1)
        end
    else
        -- create new
        local fd, err = open(path, "w")
        if fd then
            close(fd)
        else
            write(2, "touch: cannot create '"..path.."': "..(err or "failed").."\n")
            exit(1)
        end
    end
end
