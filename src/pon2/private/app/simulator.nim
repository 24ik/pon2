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

when defined(js) or defined(nimsuggest):
  import std/[jsffi, jsre, strformat, sugar]
  import karax/[karax, kdom, vdom]
  import ../[assign3, utils]
  import ../../[core]

const AssetsDir* {.define: "pon2.assets".} = "./assets"

when defined(js) or defined(nimsuggest):
  # ------------------------------------------------
  # JS - Copy Button
  # ------------------------------------------------

  proc showFlashMsg(elem: Element, html: cstring, showMs = 500) {.inline.} =
    ## Shows the flash message `html` at `elem` for `showMs` milliseconds.
    let oldHtml = elem.innerHTML
    elem.innerHTML.assign html
    runLater () => (elem.innerHTML.assign oldHtml), showMs

  func addCopyBtnHandler*(
      btn: VNode, copyStrFn: () -> string, showFlashMsgMs = 500
  ) {.inline.} =
    ## Adds the copying handler to the button.
    proc handler(ev: Event, target: VNode) =
      let btn = cast[Element](btn.dom)
      btn.disabled = true

      getClipboard().writeText copyStrFn().cstring
      btn.showFlashMsg "<span class='icon'><i class='fa-solid fa-check'></i></span><span>コピー</span>",
        showFlashMsgMs

      runLater () => (btn.disabled = false), showFlashMsgMs

    btn.addEventListener onclick, handler

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
    r"iPhone|Android.+Mobile".newRegExp in navigator.userAgent
