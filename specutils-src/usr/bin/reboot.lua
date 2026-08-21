-- reboot: restart the system (root only)
-- Usage: reboot
local uid = getuid()
if uid ~= 0 then
    write(2, "reboot: must be root\n")
    exit(1)
end

local ok, err = reboot()
if not ok then
    write(2, "reboot: " .. (err or "failed") .. "\n")
    exit(1)
end
