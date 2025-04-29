## This module implements deques.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques]

export deques

func init*[E](T: type Deque[E], initialSize = defaultInitialSize): T {.inline.} =
  {.push warning[Uninit]: off.}
  return initDeque[E](initialSize)
  {.pop.}

func toDeque2*[T](arr: openArray[T]): Deque[T] {.inline.} =
  ## Returns the deque converted from the array.
  var deque = Deque[T].init arr.len
  for elem in arr:
    deque.addLast elem

  deque
