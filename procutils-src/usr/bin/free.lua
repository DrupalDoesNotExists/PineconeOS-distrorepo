-- free: display memory usage
-- Usage: free
-- KNUCK has no meminfo syscall; print available memory info from CC runtime.
local args = {}
for i=1,select("#",...) do args[i]=select(i,...) end

write(1, "              total       used       free\n")
write(1, "Mem:     n/a         n/a         n/a\n")
write(1, "\nNote: KNUCK exposes no memory accounting to userland\n")
