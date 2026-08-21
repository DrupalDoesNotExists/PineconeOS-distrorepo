-- env / printenv: print all environment variables
-- Usage: env  or  printenv
-- Lists each environment variable as KEY=VALUE, one per line.
-- If a name argument is given, prints only that variable's value.
local args = {}
for i = 1, select("#", ...) do args[i] = select(i, ...) end

-- Built-in list of common environment variables to query.
-- The sandbox exposes getenv(name); we probe well-known names.
local CANDIDATES = {
    "HOME", "USER", "SHELL", "PATH", "TERM", "LANG", "HOSTNAME",
    "PWD", "OLDPWD", "LOGNAME", "UID", "GID", "EDITOR", "TMPDIR",
    "PINE_ROOT", "PKG_DIR",
}

if #args >= 1 then
    -- printenv NAME: print single variable
    local val = getenv(args[1])
    if val ~= nil then
        write(1, tostring(val) .. "\n")
    else
        exit(1)
    end
else
    -- Print all variables we can discover
    local printed = {}
    for _, name in ipairs(CANDIDATES) do
        local val = getenv(name)
        if val ~= nil then
            write(1, name .. "=" .. tostring(val) .. "\n")
            printed[name] = true
        end
    end
end
