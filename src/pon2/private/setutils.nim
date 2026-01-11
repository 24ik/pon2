## This module implements helpers of built-in sets.
## 

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils, typetraits]
import ./[assign]

export setutils except toSet

func `+=`*[T](a: var set[T], b: set[T]) {.inline, noinit.} =
  a.assign a + b

func `-=`*[T](a: var set[T], b: set[T]) {.inline, noinit.} =
  a.assign a - b

func `*=`*[T](a: var set[T], b: set[T]) {.inline, noinit.} =
  a.assign a * b

template toSet*(iter: untyped): untyped =
  ## Converts the iterable to a built-in set type.
  var resultSet: set[iter.elementType] = {}
  for elem in iter:
    resultSet.incl elem

  resultSet
