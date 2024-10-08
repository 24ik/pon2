## This module implements miscellaneous things.
##
## Compile Options:
## | Option                        | Description                      | Default             |
## | ----------------------------- | -------------------------------- | ------------------- |
## | `-d:pon2.assets.native=<str>` | Assets directory for native app. | `<Pon2Root>/assets` |
## | `-d:pon2.assets.web=<str>`    | Assets directory for web app.    | `./assets`          |
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[os]
import ../[misc]

const
  NativeAssetsDir* {.define: "pon2.assets.native".} = Pon2RootDir / "assets"
  WebAssetsDir* {.define: "pon2.assets.web".} = "./assets"

when defined(js):
  import std/[jsffi, strformat, sugar]
  import karax/[karax, kbase, kdom]
  import ../../core/[cell, notice]

  # ------------------------------------------------
  # JS - Clipboard
  # ------------------------------------------------

  proc getNavigator(): JsObject {.importjs: "(navigator)".} ## Returns the navigator.

  proc copyToClipboard(text: cstring) =
    ## Writes the text to the clipboard.
    getNavigator().clipboard.writeText text

  proc showFlashMessage(
      element: Element, messageHtml: string, showMs = 500.Natural
  ) {.inline.} =
    ## Sets the flash message on the element for `showMs` ms.
    let oldHtml = element.innerHTML
    element.innerHTML = messageHtml
    runLater () => (element.innerHTML = oldHtml), showMs

  func newCopyButtonHandler*(
      copyStr: () -> string, id: string, disableMs = 500.Natural
  ): () -> void {.inline.} =
    proc handler() =
      let btn = document.getElementById id.kstring

      btn.disabled = true
      copyToClipboard copyStr().cstring

      btn.showFlashMessage(
        "<span class='icon'><i class='fa-solid fa-check'></i></span>" &
          "<span>コピー</span>",
        disableMs,
      )
      runLater () => (btn.disabled = false), disableMs

    result = handler

  # ------------------------------------------------
  # JS - Images
  # ------------------------------------------------

  func cellImageSrc*(cell: Cell): kstring {.inline.} =
    ## Returns the cell image src.
    let stem =
      case cell
      of Cell.None: "none"
      of Hard: "hard"
      of Garbage: "garbage"
      of Red: "red"
      of Green: "green"
      of Blue: "blue"
      of Yellow: "yellow"
      of Purple: "purple"

    result = kstring &"{WebAssetsDir}/puyo/{stem}.png"

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

    result = kstring &"{WebAssetsDir}/noticegarbage/{stem}.png"

  const NoticeGarbageNoneImageSrc*: kstring = kstring &"{WebAssetsDir}/noticegarbage/none.png"
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

  proc newColorButton*(text = ""): ColorButton {.inline.} =
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
