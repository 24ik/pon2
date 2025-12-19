## This module implements utility functions.
##
## Compile Options:
## | Option                 | Description       | Default     |
## | ---------------------- | ----------------- | ----------- |
## | `-d:pon2.assets=<str>` | Assets directory. | `../assets` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import chroma

when defined(js) or defined(nimsuggest):
  import std/[jsffi, strformat, sugar]
  import karax/[karax, kbase, vdom, vstyles]
  import ../[assign, dom, utils]
  import ../../[app]

export chroma

when defined(js) or defined(nimsuggest):
  export kbase, vstyles

const
  AssetsDir* {.define: "pon2.assets".} = "../assets"

  SelectColor* = hsl(171, 100, 41).color
  GhostColor* = rgb(200, 200, 200).color
  WaterColor* = rgb(135, 248, 255).color
  DefaultColor* = rgb(225, 225, 225).color
  DeadColor* = hsl(348, 100, 85).color

  CounterStyleColor = rgb(255, 140, 0).color
  TranslucentStyleColor = rgba(0, 0, 0, 16).color

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  let
    counterStyle* = style(
      (StyleAttr.color, CounterStyleColor.toHtmlRgba.kstring),
      (StyleAttr.fontSize, "0.6rem".kstring),
      (StyleAttr.position, "absolute".kstring),
      (StyleAttr.top, "-0.2em".kstring),
      (StyleAttr.right, "0.3em".kstring),
      (StyleAttr.pointerEvents, "none".kstring),
    )
    bottomFixStyle* = style(
      (StyleAttr.position, "fixed".kstring),
      (StyleAttr.bottom, "calc(16px + env(safe-area-inset-bottom))".kstring),
      (StyleAttr.left, "50%".kstring),
      (StyleAttr.transform, "translateX(-50%)".kstring),
      (StyleAttr.zIndex, "100".kstring),
    )
    translucentStyle* =
      style(StyleAttr.backgroundColor, TranslucentStyleColor.toHtmlRgba.kstring)

  # ------------------------------------------------
  # JS - Copy Button
  # ------------------------------------------------

  proc showFlashMsg(elem: Element, html: kstring, showMs = 500) =
    ## Shows the flash message `html` at `elem` for `showMs` milliseconds.
    let oldHtml = elem.innerHTML
    elem.innerHTML.assign html
    runLater () => (elem.innerHTML.assign oldHtml), showMs

  func addCopyBtnHandler*(btn: VNode, copyStrProc: () -> string, showFlashMsgMs = 500) =
    ## Adds the copying handler to the button.
    proc handler(ev: Event, target: VNode) =
      let btn = cast[Element](btn.dom)
      btn.disabled = true

      getClipboard().writeText copyStrProc().kstring
      btn.showFlashMsg "<span class='icon'><i class='fa-solid fa-check'></i></span><span>コピー</span>",
        showFlashMsgMs

      runLater () => (btn.disabled = false), showFlashMsgMs

    btn.addEventListener onclick, handler

  # ------------------------------------------------
  # JS - Image
  # ------------------------------------------------

  func cellImgSrc*(cell: Cell): kstring =
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

    "{AssetsDir}/puyo/{stem}.png".fmt.kstring

  func noticeImgSrc*(notice: Notice): kstring =
    ## Returns the image source of notice garbages.
    let stem =
      case notice
      of Small: "small"
      of Large: "large"
      of Rock: "rock"
      of Star: "star"
      of Moon: "moon"
      of Crown: "crown"
      of Comet: "comet"

    "{AssetsDir}/notice/{stem}.png".fmt.kstring
  {.pop.}

  # ------------------------------------------------
  # JS - Others
  # ------------------------------------------------

  proc safeRedraw*() =
    ## Redraws the window.
    if not kxi.surpressRedraws:
      kxi.redraw
