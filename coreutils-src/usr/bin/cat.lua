-- cat: read stdin, write stdout
local data = read(0, 65536)
if data then write(1, data) end
