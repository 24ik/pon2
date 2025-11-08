## This module implements utility functions.
## 

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, sequtils, typetraits]
import ./[assign3]

when defined(js) or defined(nimsuggest):
  import std/[asyncjs, dom, jsffi, jsre, sugar]
  import ./[tables2]

  export asyncjs, jsffi

when not defined(js):
  import chronos

  export chronos

func toggle*(b: var bool) {.inline.} =
  ## Toggles the bool variable.
  b.assign not b

func incRot*[T: Ordinal](x: var T) {.inline.} =
  ## Increments `x`.
  ## If `x` is `T.high`, assigns `T.low` to `x`.
  if x == T.high:
    x.assign T.low
  else:
    x.inc

func decRot*[T: Ordinal](x: var T) {.inline.} =
  ## Decrements `x`.
  ## If `x` is `T.low`, assigns `T.high` to `x`.
  if x == T.low:
    x.assign T.high
  else:
    x.dec

func product2*[T](seqs: openArray[seq[T]]): seq[seq[T]] {.inline.} =
  ## Returns a cartesian product.
  case seqs.len
  of 0:
    @[newSeq[T]()]
  of 1:
    seqs[0].mapIt @[it]
  else:
    seqs.product

template toSet2*(iter: untyped): untyped =
  ## Converts the iterable to a built-in set type.
  var res: set[iter.elementType] = {}
  for e in iter:
    res.incl e

  res

when defined(js) or defined(nimsuggest):
  proc sleep*(ms: int): Future[void] {.inline.} =
    ## Sleeps.
    newPromise (resolve: () -> void) => (discard resolve.setTimeout ms)

  proc getSelectedIdx*(
    selectId: cstring
  ): int {.inline, importjs: "document.getElementById(#).selectedIndex".}
    ## Returns the selected index.

  proc getNavigator*(): JsObject {.inline, importjs: "(navigator)".}
    ## Returns the navigator.

  proc getClipboard*(): JsObject {.inline.} =
    ## Returns the clipboard.
    getNavigator().clipboard

  proc getElemJsObjById*(
    id: cstring
  ): JsObject {.inline, importjs: "document.getElementById(#)".} ## Returns the element.

  proc createElemJsObj*(
    id: cstring
  ): JsObject {.inline, importjs: "document.createElement(#)".}
    ## Creates an element and returns it.

  proc mobileDetected*(): bool {.inline.} =
    ## Returns `true` if a mobile device is detected.
    r"iPhone|Android.+Mobile".newRegExp in navigator.userAgent

  proc html2canvas*(
    elem: JsObject
  ): Future[JsObject] {.inline, async, importjs: "html2canvas(#)".}
    ## Runs html2canvas and returns the canvas.

  proc html2canvas*(
    elem: JsObject, scale: int
  ): Future[JsObject] {.inline, async, importjs: "html2canvas(#, {scale: #})".}
    ## Runs html2canvas and returns the canvas.
