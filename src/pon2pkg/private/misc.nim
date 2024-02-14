## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, os, parsecfg, sequtils, streams, strutils, typetraits, uri]

const Version* =
  staticRead(
    currentSourcePath().parentDir.parentDir.parentDir.parentDir / "pon2.nimble"
  ).newStringStream.loadConfig
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
  result.hostname = "twitter.com"
  result.path = "/intent/tweet"

  var queries =
    @[("ref_src", "twsrc^tfw|twcamp^buttonembed|twterm^share|twgr^"), ("text", text)]
  if hashTag != "":
    queries.add ("hashtags", hashTag)
  if uri != initUri():
    queries.add ("url", $uri)
  result.query = queries.encodeQuery

# ------------------------------------------------
# Parse
# ------------------------------------------------

func parseSomeInt*[T: SomeNumber or Natural or Positive](val: char): T {.inline.} =
  ## Converts the char or string to the given type `T`.
  ## If the conversion fails, `ValueError` will be raised.
  # NOTE: somehow generics for `val` does not work
  T parseInt $val

func parseSomeInt*[T: SomeNumber or Natural or Positive](val: string): T {.inline.} =
  ## Converts the char or string to the given type `T`.
  ## If the conversion fails, `ValueError` will be raised.
  T parseInt val

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
