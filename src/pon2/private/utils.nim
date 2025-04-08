## This module implements utilities.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, strutils, tables]
import ./[results2]

# ------------------------------------------------
# Result - Table
# ------------------------------------------------

func getRes*[K, V](
    tbl: Table[K, V] or TableRef[K, V] or OrderedTable[K, V] or OrderedTableRef[K, V],
    key: K,
): Res[V] {.inline.} =
  ## Returns the value corresponding to the key.
  if key in tbl:
    ok tbl.getOrDefault key
  else:
    err "key not found: {key}".fmt

# ------------------------------------------------
# Result - Parse
# ------------------------------------------------

func parseIntRes*(str: string): Res[int] {.inline.} =
  ## Returns the integer converted from the string.
  try:
    ok str.parseInt
  except ValueError as ex:
    err ex.msg

# ------------------------------------------------
# Warning-suppress
# ------------------------------------------------

func sum2*[T: SomeNumber](arr: openArray[T]): T {.inline.} =
  ## Returns a summation of the array.
  var res = 0.T
  for e in arr:
    res.inc e

  res
