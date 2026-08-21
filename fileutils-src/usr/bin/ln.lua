-- ln: create links
-- Usage: ln [-s] <src> <dst>
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

local symlink_mode = false
local src, dst

local i = 1
while i <= #args do
    local a = args[i]
    if a == "-s" then
        symlink_mode = true
    elseif a:sub(1,1) == "-" and #a > 1 then
        for j=2,#a do
            local c = a:sub(j,j)
            if c == "s" then symlink_mode = true
            else
                write(2, "ln: unknown option: -"..c.."\n")
                exit(1)
            end
        end
    elseif not src then
        src = a
    elseif not dst then
        dst = a
    end
    i = i + 1
end

if not src or not dst then
    write(2, "usage: ln [-s] <source> <target>\n")
    exit(1)
end

local ok, err
if symlink_mode then
    ok, err = symlink(src, dst)
else
    ok, err = link(src, dst)
end

if not ok then
    write(2, "ln: failed to link '"..src.."' -> '"..dst.."': "..(err or "unknown error").."\n")
    exit(1)
end
