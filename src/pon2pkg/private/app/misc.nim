## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js):
  import std/[jsffi, strformat, sugar]
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

  const WebRootDir = when defined(pon2.marathon): ".." else: "."

  func cellImageSrc*(cell: Cell): kstring {.inline.} =
    ## Returns the cell image src.
    let stem =
      case cell
      of None: "none"
      of Hard: "hard"
      of Garbage: "garbage"
      of Red: "red"
      of Green: "green"
      of Blue: "blue"
      of Yellow: "yellow"
      of Purple: "purple"

    result = kstring &"{WebRootDir}/assets/puyo/{stem}.png"

  func noticeGarbageImageSrc*(notice: NoticeGarbage): kstring {.inline.} =
    ## Returns the notice garbage image src.
    let stem =
      case notice
      of Small: "small"
      of Big: "big"
      of Rock: "rock"
      of Star: "star"
      of Moon: "moon"
      of Crown: "crown"
      of Comet: "comet"

    result = kstring &"{WebRootDir}/assets/noticegarbage/{stem}.png"

  const NoticeGarbageNoneImageSrc*: kstring = kstring &"{WebRootDir}/assets/noticegarbage/none.png"
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
