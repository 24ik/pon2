--threads:on
--opt:speed
--define:danger

#[
These are needed at Nim==1.6.12.
In #devel, tlsEmulation and useMalloc can (or should) be removed,
and all memory management strategies can be allowed.
]#
--tlsEmulation:off
--define:useMalloc
--mm:arc

when defined linux:
  discard
elif defined windows:
  --passL:"-static"
  --define:"avx2=false"
else:
  --define:"avx2=false"
  --define:"bmi2=false"