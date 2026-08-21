-- echo: print args
local out = {}
for i = 1, select("#", ...) do out[i] = tostring(select(i, ...)) end
print(table.concat(out, " "))