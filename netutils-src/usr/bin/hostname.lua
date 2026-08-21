-- hostname: show or set the system hostname
-- Usage: hostname [name]
-- Uses environment variable HOSTNAME for persistence within the session.
-- The KNUCK kernel does not expose os.getComputerLabel() to userland,
-- so hostname is stored in the process environment.

local function usage()
    print("usage: hostname [name]")
    exit(1)
end

local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

if #args == 0 then
    -- Show current hostname
    local h = getenv("HOSTNAME")
    if h and h ~= "" then
        print(h)
    else
        print("localhost")
    end
    exit(0)
elseif #args == 1 then
    local name = args[1]
    -- Validate hostname (basic checks)
    if #name > 255 then
        print("hostname: name too long (max 255 characters)")
        exit(1)
    end
    if name == "" then
        print("hostname: name cannot be empty")
        exit(1)
    end
    -- Set hostname
    setenv("HOSTNAME", name)
    print("hostname: hostname set to " .. name)
    exit(0)
else
    usage()
end
