## This module implements common functions.
##
## Compile Options:
## | Option                 | Description       | Default    |
## | ---------------------- | ----------------- | ---------- |
## | `-d:pon2.assets=<str>` | Assets directory. | `./assets` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

const AssetsDir* {.define: "pon2.assets".} = "./assets"

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js):
  import std/[dom, jsffi, strformat, sugar]
  import karax/[karax]
  import ../[assign3]
  import ../../[core]

  # ------------------------------------------------
  # JS - Copy Button
  # ------------------------------------------------

  proc getNavigator(): JsObject {.importjs: "(navigator)".} ## Returns the navigator.

  proc storeToClipboard(text: string) {.inline.} =
    ## Writes the text to the clipboard.
    getNavigator().clipboard.writeText text.cstring

  proc showFlashMsg(elem: Element, html: cstring, showMs = 500) {.inline.} =
    ## Shows the flash message `html` at `elem` for `showMs` milliseconds.
    let oldHtml = elem.innerHTML
    elem.innerHTML.assign html
    runLater () => (elem.innerHTML.assign oldHtml), showMs

  func initCopyButtonHandler*(
      copyStr: () -> string, btnId: cstring, showFlashMsgMs = 500
  ): () -> void {.inline.} =
    ## Returns the handler for copy buttons.
    proc handler() =
      let btn = btnId.getElementById
      btn.disabled = true

      copyStr().storeToClipboard
      btn.showFlashMsg "<span class='icon'><i class='fa-solid fa-check'></i></span><span>コピー</span>",
        showFlashMsgMs

      runLater () => (btn.disabled = false), showFlashMsgMs

    handler

  # ------------------------------------------------
  # JS - Image
  # ------------------------------------------------

  func cellImgSrc*(cell: Cell): cstring {.inline.} =
    ## Returns the image source of cells.
    let stem =
      case cell
      of Cell.None: "none"
      of Hard: "hard"
      of Garbage: "garbage"
      of Cell.Red: "red"
      of Cell.Green: "green"
      of Cell.Blue: "blue"
      of Cell.Yellow: "yellow"
      of Cell.Purple: "purple"

    "{AssetsDir}/puyo/{stem}.png".fmt.cstring

  func noticeGarbageImgSrc*(notice: NoticeGarbage): cstring {.inline.} =
    ## Returns the image source of notice garbages.
    let stem =
      case notice
      of Small: "small"
      of Big: "big"
      of Rock: "rock"
      of Star: "star"
      of Moon: "moon"
      of Crown: "crown"
      of Comet: "comet"

    "{AssetsDir}/notice/{stem}.png".fmt.cstring

  # ------------------------------------------------
  # JS - Others
  # ------------------------------------------------

  proc isMobile*(): bool {.inline.} =
    ## Returns `true` if a mobile device is detected.
    const MobileRegex = "iPhone|Android.+Mobile".newRegExp
    MobileRegex in navigator.userAgent
