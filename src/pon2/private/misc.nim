## This module implements miscellaneous things.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import
  std/[
    algorithm, deques, os, parsecfg, random, sequtils, streams, strutils, typetraits,
    uri,
  ]

func splitPath2(path: string): tuple[head: string, tail: string] {.inline.} =
  ## Returns the parent directory.
  when not defined(js):
    path.splitPath
  else:
    if '\\' in path:
      let paths = path.rsplit('\\', 1)
      (head: paths[0], tail: paths[1])
    else:
      path.splitPath

func joinPath2(head, tail: string): string {.inline.} =
  ## Returns the path by joining two paths.
  when not defined(js):
    head / tail
  else:
    if '\\' in head:
      head & '\\' & tail
    else:
      head / tail

proc getPon2RootDir(): string {.inline.} =
  ## Returns the root directory of Pon2.
  let
    (head, _) = currentSourcePath().splitPath2.head.splitPath2.head.splitPath2
    (head2, tail2) = head.splitPath2

  result = if tail2 == "src": head2 else: head

const
  Pon2RootDir* = getPon2RootDir()
  Pon2Version* = Pon2RootDir
    .joinPath2("pon2.nimble").staticRead.newStringStream.loadConfig
    .getSectionValue("", "version")

# ------------------------------------------------
# Warning-suppress Version
# ------------------------------------------------

func sum2*[T: SomeNumber or Natural](arr: openArray[T]): T {.inline.} =
  ## Returns a summation of the array.
  result = 0.T
  for e in arr:
    result.inc e

template toSet2*(iter: untyped): untyped =
  ## Converts the iterable to a built-in set type.
  var res: set[iter.elementType] = {}
  for e in iter:
    res.incl e

  res

# ------------------------------------------------
# X
# ------------------------------------------------

func initXLink*(text = "", hashTag = "", uri = initUri()): Uri {.inline.} =
  ## Returns a URI for posting to X.
  result = initUri()
  result.scheme = "https"
  result.hostname = "x.com"
  result.path = "/intent/tweet" # NOTE: "/post" does not open the X app.

  var queries = @[("text", text)]
  if hashTag != "":
    queries.add ("hashtags", hashTag)
  if uri != initUri():
    queries.add ("url", $uri)
  result.query = queries.encodeQuery

# ------------------------------------------------
# Parse
# ------------------------------------------------

func parseSomeInt*[T: SomeNumber or Natural or Positive](val: string): T {.inline.} =
  ## Converts the string to the given type `T`.
  ## If the conversion fails, `ValueError` will be raised.
  T parseInt val

func parseSomeInt*[T: SomeNumber or Natural or Positive](val: char): T {.inline.} =
  ## Converts the char to the given type `T`.
  ## If the conversion fails, `ValueError` will be raised.
  parseSomeInt[T] $val

# ------------------------------------------------
# Deque
# ------------------------------------------------

func copy*[T](deque: Deque[T]): Deque[T] {.inline.} =
  ## Returns a copy of the deque.
  result = initDeque(deque.len)
  for e in deque:
    result.addLast e

func insert*[T](deque: var Deque[T], item: sink T, idx = 0.Natural) {.inline.} =
  ## Inserts the item at the index.
  ## This is an `O(n)` operation.
  var newDeque = initDeque[T](deque.len.succ)
  for itemIdx in 0 ..< deque.len.succ:
    newDeque.addLast if itemIdx == idx: item else: deque.popFirst

  deque = newDeque

func delete*[T](deque: var Deque[T], idx: Natural) {.inline.} =
  ## Deletes the item at the index.
  ## This is an `O(n)` operation.
  var newDeque = initDeque[T](deque.len.pred)
  for itemIdx in 0 ..< deque.len:
    let item = deque.popFirst
    if itemIdx != idx:
      newDeque.addLast item

  deque = newDeque

# ------------------------------------------------
# Others
# ------------------------------------------------

func toggle*(b: var bool) {.inline.} = ## Toggles the value.
  b = not b

func product2*[T](x: openArray[seq[T]]): seq[seq[T]] {.inline.} =
  ## Returns a cartesian product.
  ## This version works on any length.
  case x.len
  of 0:
    @[newSeq[T](0)]
  of 1:
    x[0].mapIt @[it]
  else:
    x.product

iterator zip*[T, U, V](
    s1: openArray[T], s2: openArray[U], s3: openArray[V]
): (T, U, V) {.inline.} =
  ## Yields a combination of elements.
  ## Longer array\[s\] will be truncated.
  let minLen = [s1.len, s2.len, s3.len].min
  for i in 0 ..< minLen:
    yield (s1[i], s2[i], s3[i])

func sample*[T](rng: var Rand, arr: openArray[T], count: Natural): seq[T] {.inline.} =
  ## Selects and returns `count` elements in the array without duplicates.
  var arr2 = arr.toSeq
  rng.shuffle arr2
  result = arr2[0 ..< count]

func incRot*[T: Ordinal](x: var T) {.inline.} =
  ## Rotating `inc`.
  if x == T.high:
    x = T.low
  else:
    x.inc

func decRot*[T: Ordinal](x: var T) {.inline.} =
  ## Rotating `dec`.
  if x == T.low:
    x = T.high
  else:
    x.dec
