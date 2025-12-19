## This module implements tables.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, tables]
import ../[utils]

export utils
export tables except `[]`

func `[]`*[K, V](
    table: Table[K, V] or TableRef[K, V] or OrderedTable[K, V] or OrderedTableRef[K, V],
    key: K,
): Pon2Result[V] {.inline, noinit.} =
  ## Returns the value corresponding to the key.
  if key in table:
    ok table.getOrDefault key
  else:
    err "key not found: {key}".fmt
