## This module implements URI-related functions.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[uri]
import ./[assign]

export uri

func updatedQuery*(
    query: string, key, val: string, removeEmptyVal = false
): string {.inline, noinit.} =
  ## Returns the query update with the specified key and value.
  var
    newKeyVals = newSeq[(string, string)]()
    keyFound = false

  for (key2, val2) in query.decodeQuery:
    if key2 == key:
      if not (removeEmptyVal and val.len == 0):
        newKeyVals.add (key, val)
      keyFound.assign true
    else:
      if not (removeEmptyVal and val2.len == 0):
        newKeyVals.add (key2, val2)

  if not keyFound and not (removeEmptyVal and val.len == 0):
    newKeyVals.add (key, val)

  newKeyVals.encodeQuery
