-- halt: shut down the system (root only)
-- Usage: halt
local uid = getuid()
if uid ~= 0 then
    write(2, "halt: must be root\n")
    exit(1)
end

local ok, err = halt()
if not ok then
    write(2, "halt: " .. (err or "failed") .. "\n")
    exit(1)
end
