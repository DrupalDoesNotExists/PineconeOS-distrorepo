-- nice: run a command with modified scheduling priority
-- Usage: nice [-n increment] <command> [args...]
-- Default increment is 10 (lower priority).
-- Without a command, prints the current nice value.
local args = {}
for i = 1, select("#", ...) do args[i] = select(i, ...) end

local increment = 10
local cmd_start = 1

local i = 1
while i <= #args do
    if args[i] == "-n" then
        i = i + 1
        if i > #args then
            write(2, "nice: option requires an argument -- n\n")
            exit(1)
        end
        increment = tonumber(args[i])
        if not increment then
            write(2, "nice: invalid increment: '" .. args[i] .. "'\n")
            exit(1)
        end
        cmd_start = i + 1
    else
        break
    end
    i = i + 1
end

if cmd_start > #args then
    -- No command: just print current priority
    local prio = getpriority()
    if prio ~= nil then
        write(1, tostring(prio) .. "\n")
    end
else
    -- Get current priority and adjust
    local cur = getpriority()
    if cur ~= nil then
        local new_prio = cur + increment
        setpriority(nil, new_prio)
    end
    -- Execute the command via exec
    local cmd = args[cmd_start]
    exec(cmd, table.unpack(args, cmd_start + 1, #args))
end
