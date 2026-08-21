-- chown: change file owner
-- Usage: chown <uid>[:<gid>] <path...>
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args < 2 then
    write(2, "usage: chown <uid>[:<gid>] <file...>\n")
    exit(1)
end

local spec = args[1]
local uid, gid

local colon = spec:find(":")
if colon then
    uid = tonumber(spec:sub(1, colon-1))
    gid = tonumber(spec:sub(colon+1))
else
    uid = tonumber(spec)
end

if not uid then
    write(2, "chown: invalid uid: '"..spec.."'\n")
    exit(1)
end

for i=2,#args do
    local path = args[i]
    local ok, err = chown(path, uid, gid)
    if not ok then
        write(2, "chown: cannot change owner of '"..path.."': "..(err or "failed").."\n")
        exit(1)
    end
end
