## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[kbase, kdom]
import std/[sugar]
import ../../../corepkg/[cell]

# ------------------------------------------------
# Clipboard
# ------------------------------------------------

proc copyToClipboard(text: kstring)
  {.importjs: "navigator.clipboard.writeText(#);".}
  ## Sets the text to the clipboard.

proc showFlashMessage(element: Element, messageHtml: string,
                      timeMs = Natural 500) {.inline.} =
  ## Sets the flash message on the element for `timeMs` ms.
  let oldHtml = element.innerHTML
  element.innerHTML = messageHtml
  discard setTimeout(() => (element.innerHTML = oldHtml), timeMs)

func initCopyButtonHandler*(copyStr: () -> string, id: string,
                            disableMs = Natural 500): () -> void {.inline.} =
  proc handler =
    let btn = document.getElementById id.kstring

    btn.disabled = true
    copyToClipboard copyStr().kstring

    btn.showFlashMessage(
      "<span class='icon'><i class='fa-solid fa-check'></i></span>" &
      "<span>コピー</span>", disableMs)
    discard setTimeout(() => (btn.disabled = false), disableMs)

  result = handler

# ------------------------------------------------
# Images
# ------------------------------------------------

func cellImageSrc*(cell: Cell): kstring {.inline.} =
  ## Returns the image src.
  kstring case cell
  of None: "./assets/puyo/none.png"
  of Hard: "./assets/puyo/hard.png"
  of Garbage: "./assets/puyo/garbage.png"
  of Red: "./assets/puyo/red.png"
  of Green: "./assets/puyo/green.png"
  of Blue: "./assets/puyo/blue.png"
  of Yellow: "./assets/puyo/yellow.png"
  of Purple: "./assets/puyo/purple.png"

# ------------------------------------------------
# Others
# ------------------------------------------------

proc isMobile*: bool
  {.importjs: "navigator.userAgent.match(/iPhone|Android.+Mobile/)".}
  ## Returns `true` if the mobile is detected.
