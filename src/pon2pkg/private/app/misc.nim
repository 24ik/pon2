## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js):
  import std/[jsffi, sugar]
  import karax/[kbase, kdom]
  import ../../core/[cell, notice]

  # ------------------------------------------------
  # JS - Clipboard
  # ------------------------------------------------

  proc getNavigator(): JsObject {.importjs: "(navigator)".} ## Returns the navigator.

  proc copyToClipboard(text: kstring) =
    ## Writes the text to the clipboard.
    getNavigator().clipboard.writeText text

  proc showFlashMessage(
      element: Element, messageHtml: string, timeMs = Natural 500
  ) {.inline.} =
    ## Sets the flash message on the element for `timeMs` ms.
    let oldHtml = element.innerHTML
    element.innerHTML = messageHtml
    discard setTimeout(() => (element.innerHTML = oldHtml), timeMs)

  func initCopyButtonHandler*(
      copyStr: () -> string, id: string, disableMs = Natural 500
  ): () -> void {.inline.} =
    proc handler() =
      let btn = document.getElementById id.kstring

      btn.disabled = true
      copyToClipboard copyStr().kstring

      btn.showFlashMessage(
        "<span class='icon'><i class='fa-solid fa-check'></i></span>" &
          "<span>コピー</span>",
        disableMs,
      )
      discard setTimeout(() => (btn.disabled = false), disableMs)

    result = handler

  # ------------------------------------------------
  # JS - Images
  # ------------------------------------------------

  func cellImageSrc*(cell: Cell): kstring {.inline.} =
    ## Returns the cell image src.
    kstring case cell
    of None: "../assets/puyo/none.png"
    of Hard: "../assets/puyo/hard.png"
    of Garbage: "../assets/puyo/garbage.png"
    of Red: "../assets/puyo/red.png"
    of Green: "../assets/puyo/green.png"
    of Blue: "../assets/puyo/blue.png"
    of Yellow: "../assets/puyo/yellow.png"
    of Purple: "../assets/puyo/purple.png"

  func noticeGarbageImageSrc*(notice: NoticeGarbage): kstring {.inline.} =
    ## Returns the notice garbage image src.
    kstring case notice
    of Small: "../assets/noticegarbage/small.png"
    of Big: "../assets/noticegarbage/big.png"
    of Rock: "../assets/noticegarbage/rock.png"
    of Star: "../assets/noticegarbage/star.png"
    of Moon: "../assets/noticegarbage/moon.png"
    of Crown: "../assets/noticegarbage/crown.png"
    of Comet: "../assets/noticegarbage/comet.png"

  const NoticeGarbageNoneImageSrc*: kstring = kstring"../assets/noticegarbage/none.png"
    ## Image src of the no notice garbage.

  # ------------------------------------------------
  # JS - Others
  # ------------------------------------------------

  proc isMobile*(): bool {.
    importjs: "navigator.userAgent.match(/iPhone|Android.+Mobile/)"
  .} ## Returns `true` if the mobile is detected.

else:
  import std/[math]
  import nigui

  # ------------------------------------------------
  # Native - Button
  # ------------------------------------------------

  type ColorButton* = ref object of Button
    ## [Button with color](https://github.com/simonkrauter/NiGui/issues/9).

  proc initColorButton*(text = ""): ColorButton {.inline.} =
    ## Returns a new color button.
    result = new ColorButton
    result.init
    result.text = text

  method handleDrawEvent*(control: ColorButton, event: DrawEvent) =
    let canvas = event.control.canvas
    canvas.areaColor = control.backgroundColor
    canvas.textColor = control.textColor
    canvas.lineColor = control.textColor
    canvas.drawRectArea(0, 0, control.width, control.height)
    canvas.drawTextCentered(control.text)
    canvas.drawRectOutline(0, 0, control.width, control.height)

  # ------------------------------------------------
  # Native - Others
  # ------------------------------------------------

  # FIXME: these are very ad hoc implementations and need improvement

  const Dpi = when defined(windows): 144 else: 120

  func pt*(px: int): float {.inline.} =
    ## Returns `pt` converted from `px`.
    px / Dpi * 72

  func px*(pt: float): int {.inline.} =
    ## Returns `px` converted from `pt`.
    (pt / 72 * Dpi).round.int
