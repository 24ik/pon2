## This module implements crit-bit trees.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[critbits]

export critbits

func toCritBitTree2*(
    items: sink openArray[string]
): CritBitTree[void] {.inline, noinit.} =
  try:
    items.toCritBitTree
  except Exception:
    CritBitTree[void].default
