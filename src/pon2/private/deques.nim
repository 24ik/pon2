## This module implements deques.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques]

export deques except toDeque

func init*[E](
    T: type Deque[E], initialSize = defaultInitialSize
): T {.inline, noinit.} =
  {.push warning[Uninit]: off.}
  return initDeque[E](initialSize)
  {.pop.}

func toDeque*[T](items: openArray[T]): Deque[T] {.inline, noinit.} =
  ## Returns the deque converted from the array.
  var deque = Deque[T].init items.len
  for item in items:
    deque.addLast item

  deque

func insert*[T](self: var Deque[T], item: sink T, idx: int) {.inline, noinit.} =
  ## Inserts the item at the index `idx`.
  var elems = Deque[T].init idx
  for _ in 1 .. idx:
    elems.addLast self.popFirst

  self.addFirst item

  for _ in 1 .. idx:
    self.addFirst elems.popLast

func del*[T](self: var Deque[T], idx: int) {.inline, noinit.} =
  ## Deletes `idx`-th element of the deque.
  var elems = Deque[T].init idx
  for _ in 1 .. idx:
    elems.addLast self.popFirst

  self.popFirst

  for _ in 1 .. idx:
    self.addFirst elems.popLast

iterator mpairs*[T](self: var Deque[T]): tuple[key: int, val: var T] {.inline.} =
  ## Yields and index-value pair in the deque.
  for i in 0 ..< self.len:
    yield (i, self[i])
