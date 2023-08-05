--opt:speed
--define:danger

when defined linux:
  discard
elif defined windows:
  --passL:"-static"
  --define:"avx2=false"
else:
  --define:"avx2=false"
  --define:"bmi2=false"