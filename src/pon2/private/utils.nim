## This module implements utility functions.
## 

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[assign]

when defined(js) or defined(nimsuggest):
  import std/[asyncjs, dom, jsffi, jsre, sugar]

  export asyncjs, jsffi

func toggle*(x: var bool) {.inline, noinit.} =
  ## Toggles the bool variable.
  x.assign not x

func rotateSucc*[T: Ordinal](x: T): T {.inline, noinit.} =
  ## Returns the successor of `x`.
  ## If `x` is `T.high`, returns `T.low`.
  if x == T.high: T.low else: x.succ

func rotatePred*[T: Ordinal](x: T): T {.inline, noinit.} =
  ## Returns the predecessor of `x`.
  ## If `x` is `T.low`, returns `T.high`.
  if x == T.low: T.high else: x.pred

func rotateInc*[T: Ordinal](x: var T) {.inline, noinit.} =
  ## Increments `x`.
  ## If `x` is `T.high`, assigns `T.low` to `x`.
  if x == T.high:
    x.assign T.low
  else:
    x.inc

func rotateDec*[T: Ordinal](x: var T) {.inline, noinit.} =
  ## Decrements `x`.
  ## If `x` is `T.low`, assigns `T.high` to `x`.
  if x == T.low:
    x.assign T.high
  else:
    x.dec

when defined(js) or defined(nimsuggest):
  proc sleep*(ms: int): Future[void] {.inline, noinit.} =
    ## Sleeps.
    newPromise (resolve: () -> void) => (discard resolve.setTimeout ms)

  proc mobileDetected*(): bool {.inline, noinit.} =
    ## Returns `true` if a mobile device is detected.
    r"iPhone|Android.+Mobile".newRegExp in navigator.userAgent

  proc html2canvas*(
    elem: JsObject, id: cstring, scale = 1
  ): Future[JsObject] {.
    inline,
    noinit,
    async,
    importjs:
      "html2canvas(#, {onclone: (doc) => {const cloneElem = doc.getElementById(#); cloneElem.setAttribute('data-theme', 'light'); cloneElem.style.backgroundColor = 'white'; cloneElem.style.color = 'black';}, scale: #})"
  .}
    ## Runs html2canvas and returns the canvas.
    ## The target element is set to the light mode.
