## This module bit operations.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops]
import ./[assign3]

# ------------------------------------------------
# In-place Operations
# ------------------------------------------------

func mask2*[T: SomeInteger](v: var T, mask: T or Slice[int]) {.inline.} =
  ## In-place-and operation.
  v.assign v.masked mask

func setMask2*[T: SomeInteger](v: var T, mask: T or Slice[int]) {.inline.} =
  ## In-place-or operation.
  v.assign v.setMasked mask

func clearMask2*[T: SomeInteger](v: var T, mask: T or Slice[int]) {.inline.} =
  ## In-place-andnot operation.
  v.assign v.clearMasked mask

# ------------------------------------------------
# Bitwise-and
# ------------------------------------------------

func bitand2*[T: SomeInteger](x1, x2: T): T {.inline.} =
  ## Bitwise-and operation.
  x1 and x2

func bitand2*[T: SomeInteger](x1, x2, x3: T): T {.inline.} =
  ## Bitwise-and operation.
  x1 and x2 and x3

func bitand2*[T: SomeInteger](x1, x2, x3, x4: T): T {.inline.} =
  ## Bitwise-and operation.
  (x1 and x2) and (x3 and x4)

func bitand2*[T: SomeInteger](x1, x2, x3, x4, x5: T): T {.inline.} =
  ## Bitwise-and operation.
  (x1 and x2 and x3) and (x4 and x5)

func bitand2*[T: SomeInteger](x1, x2, x3, x4, x5, x6: T): T {.inline.} =
  ## Bitwise-and operation.
  ((x1 and x2) and (x3 and x4)) and (x5 and x6)

func bitand2*[T: SomeInteger](x1, x2, x3, x4, x5, x6, x7: T): T {.inline.} =
  ## Bitwise-and operation.
  ((x1 and x2) and (x3 and x4)) and (x5 and x6 and x7)

func bitand2*[T: SomeInteger](x1, x2, x3, x4, x5, x6, x7, x8: T): T {.inline.} =
  ## Bitwise-and operation.
  ((x1 and x2) and (x3 and x4)) and ((x5 and x6) and (x7 and x8))

# ------------------------------------------------
# Bitwise-or
# ------------------------------------------------

func bitor2*[T: SomeInteger](x1, x2: T): T {.inline.} =
  ## Bitwise-or operation.
  x1 or x2

func bitor2*[T: SomeInteger](x1, x2, x3: T): T {.inline.} =
  ## Bitwise-or operation.
  x1 or x2 or x3

func bitor2*[T: SomeInteger](x1, x2, x3, x4: T): T {.inline.} =
  ## Bitwise-or operation.
  (x1 or x2) or (x3 or x4)

func bitor2*[T: SomeInteger](x1, x2, x3, x4, x5: T): T {.inline.} =
  ## Bitwise-or operation.
  (x1 or x2 or x3) or (x4 or x5)

func bitor2*[T: SomeInteger](x1, x2, x3, x4, x5, x6: T): T {.inline.} =
  ## Bitwise-or operation.
  ((x1 or x2) or (x3 or x4)) or (x5 or x6)

func bitor2*[T: SomeInteger](x1, x2, x3, x4, x5, x6, x7: T): T {.inline.} =
  ## Bitwise-or operation.
  ((x1 or x2) or (x3 or x4)) or (x5 or x6 or x7)

func bitor2*[T: SomeInteger](x1, x2, x3, x4, x5, x6, x7, x8: T): T {.inline.} =
  ## Bitwise-or operation.
  ((x1 or x2) or (x3 or x4)) or ((x5 or x6) or (x7 or x8))
