## This module implements crit-bit trees.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[critbits]

export critbits except toCritBitTree

func toCritBitTree*(
    items: sink openArray[string]
): CritBitTree[void] {.inline, noinit.} =
  try:
    critbits.toCritBitTree items
  except Exception:
    CritBitTree[void].default

proc toCritBitTree*[T](
    pairs: sink openArray[(string, T)]
): CritBitTree[T] {.inline, noinit.} =
  try:
    {.push warning[Uninit]: off.}
    {.push warning[ProveInit]: off.}
    return critbits.toCritBitTree pairs
    {.pop.}
    {.pop.}
  except Exception:
    return CritBitTree[T].default
