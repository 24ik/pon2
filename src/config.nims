switch("threads", "on")
switch("opt", "speed")
switch("define", "danger")

#[
These are necessary in Nim==1.6.12.
In #devel, tlsEmulation and useMalloc can (or should) be removed,
and all memory management strategies are allowed.
]#
switch("tlsEmulation", "off")
switch("define", "useMalloc")
switch("mm", "arc")