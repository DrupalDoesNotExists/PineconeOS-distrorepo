-- umask: get or set the file mode creation mask
-- Usage: umask [mask]
-- mask is an octal number (e.g. 022). Without arguments, prints the current mask.
local args = {}
for i = 1, select("#", ...) do args[i] = select(i, ...) end

if #args >= 1 then
    -- Parse octal mask
    local mask_str = args[1]
    -- Strip leading 0o or 0X prefix if present
    local octal = mask_str:match("^0[oO](.+)$") or mask_str:match("^0([0-7]+)$") or mask_str:match("^([0-7]+)$")
    if not octal then
        write(2, "umask: invalid octal number: '" .. mask_str .. "'\n")
        exit(1)
    end
    local mask = tonumber(octal, 8)
    if not mask then
        write(2, "umask: invalid octal number: '" .. mask_str .. "'\n")
        exit(1)
    end
    local old = umask(mask)
    if old ~= nil then
        -- Print old mask in octal format
        write(1, string.format("%04o\n", old))
    end
else
    -- No argument: print current mask
    local old = umask()
    if old ~= nil then
        write(1, string.format("%04o\n", old))
    else
        write(1, "0022\n")
    end
end
