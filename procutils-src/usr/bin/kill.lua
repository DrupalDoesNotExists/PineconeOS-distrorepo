-- kill: send signal to a process
-- Usage: kill [-s SIGNAL] PID  or  kill [-SIGNAL] PID
-- Default signal is SIGTERM (15).
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

local SIGNALS = {
    HUP=1, INT=2, QUIT=3, KILL=9, USR1=10, USR2=12,
    PIPE=13, ALRM=14, TERM=15, CHLD=17, CONT=18, STOP=19,
}

local sig = 15  -- SIGTERM default
local pid = nil

local i = 1
while i <= #args do
    local a = args[i]
    if a == "-s" then
        i = i + 1
        if i > #args then
            write(2, "kill: option requires an argument -- s\n")
            exit(1)
        end
        local s = args[i]
        sig = SIGNALS[s:upper()] or tonumber(s)
        if not sig then
            write(2, "kill: invalid signal: '" .. s .. "'\n")
            exit(1)
        end
    elseif a:sub(1, 1) == "-" and #a > 1 then
        local rest = a:sub(2)
        local sname = rest:match("^([A-Za-z]+)") or ""
        local num = tonumber(rest)
        if sname ~= "" and SIGNALS[sname:upper()] then
            sig = SIGNALS[sname:upper()]
        elseif num then
            sig = num
        else
            write(2, "kill: invalid signal: '" .. rest .. "'\n")
            exit(1)
        end
    else
        pid = tonumber(a)
        if not pid then
            write(2, "kill: invalid pid: '" .. a .. "'\n")
            exit(1)
        end
    end
    i = i + 1
end

if not pid then
    write(2, "usage: kill [-s SIGNAL] PID\n")
    exit(1)
end

local ok, err = kill(pid, sig)
if not ok then
    write(2, "kill: " .. tostring(err or "failed") .. "\n")
    exit(1)
end
