## This module implements tables.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, tables]
import ./[results2]

export tables

func getRes*[K, V](
    tbl: Table[K, V] or TableRef[K, V] or OrderedTable[K, V] or OrderedTableRef[K, V],
    key: K,
): Res[V] {.inline.} =
  ## Returns the value corresponding to the key.
  if key in tbl:
    ok tbl.getOrDefault key
  else:
    err "key not found: {key}".fmt
