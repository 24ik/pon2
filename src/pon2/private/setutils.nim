## This module implements helpers of built-in sets.
## 

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils, typetraits]

export setutils except toSet

template toSet*(iter: untyped): untyped =
  ## Converts the iterable to a built-in set type.
  var resultSet: set[iter.elementType] = {}
  for elem in iter:
    resultSet.incl elem

  resultSet
