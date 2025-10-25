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
{.push experimental: "views".}

import chroma

when defined(js) or defined(nimsuggest):
  import std/[jsffi, jsre, strformat, sugar]
  import karax/[karax, kdom, vdom, vstyles]
  import ../[assign3, utils]
  import ../../[app]

const
  AssetsDir* {.define: "pon2.assets".} = "../assets"

  SelectColor* = hsl(171, 100, 41).color
  GhostColor* = rgb(200, 200, 200).color
  WaterColor* = rgb(135, 248, 255).color
  DefaultColor* = rgb(225, 225, 225).color

  CounterStyleColor = rgb(255, 140, 0).color
  TranslucentStyleColor = rgba(0, 0, 0, 16).color

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  type
    SimulatorVNodeHelper* = object ## Helper for making VNode of simulators.
      goalId*: cstring
      cameraReadyId*: cstring
      markResultOpt*: Opt[MarkResult]

    StudioVNodeHelper* = object ## Helper for making VNode of studios.
      isReplaySimulator*: bool
      settingId*: cstring

    VNodeHelper* = object ## Helper for making VNode.
      mobile*: bool
      simulator*: SimulatorVNodeHelper
      studioOpt*: Opt[StudioVNodeHelper]

  let
    counterStyle* = style(
      (StyleAttr.color, CounterStyleColor.toHtmlHex.cstring),
      (StyleAttr.fontSize, "0.6rem".cstring),
      (StyleAttr.position, "absolute".cstring),
      (StyleAttr.top, "-0.2em".cstring),
      (StyleAttr.right, "0.3em".cstring),
      (StyleAttr.pointerEvents, "none".cstring),
    )
    bottomFixStyle* = style(
      (StyleAttr.position, "fixed".cstring),
      (StyleAttr.bottom, "calc(16px + env(safe-area-inset-bottom))".cstring),
      (StyleAttr.left, "50%".cstring),
      (StyleAttr.transform, "translateX(-50%)".cstring),
      (StyleAttr.zIndex, "100".cstring),
    )
    translucentStyle* =
      style(StyleAttr.backgroundColor, TranslucentStyleColor.toHtmlHex.cstring)

  # ------------------------------------------------
  # JS - Dereference
  # ------------------------------------------------

  func derefSimulator*(
      self: ref Simulator, helper: VNodeHelper
  ): var Simulator {.inline.} =
    ## Dereferences the simulator.
    self[]

  # NOTE: views rejects this procedure
  # ref: https://github.com/24ik/pon2/issues/224#issuecomment-3445207849
  {.pop.}
  proc derefSimulator*(self: ref Studio, helper: VNodeHelper): var Simulator =
    ## Dereferences the simulator.
    if helper.studioOpt.unsafeValue.isReplaySimulator:
      return self[].replaySimulator
    else:
      return self[].simulator

  {.push experimental: "views".}

  # ------------------------------------------------
  # JS - VNode Helper
  # ------------------------------------------------

  proc isMobile(): bool {.inline.} =
    ## Returns `true` if a mobile device is detected.
    r"iPhone|Android.+Mobile".newRegExp in navigator.userAgent

  func init(
      T: type SimulatorVNodeHelper, simulator: Simulator, rootId: cstring
  ): T {.inline.} =
    T(
      goalId: "pon2-simulator-goal-" & rootId,
      cameraReadyId: "pon2-simulator-cameraready-" & rootId,
      markResultOpt: simulator.mark,
    )

  func init(
      T: type StudioVNodeHelper, rootId: cstring, isReplaySimulator: bool
  ): T {.inline.} =
    T(settingId: "pon2-studio-setting-" & rootId, isReplaySimulator: isReplaySimulator)

  proc init*(
      T: type VNodeHelper, simulatorRef: ref Simulator, rootId: cstring
  ): T {.inline.} =
    VNodeHelper(
      mobile: isMobile(),
      simulator: SimulatorVNodeHelper.init(simulatorRef[], rootId),
      studioOpt: Opt[StudioVNodeHelper].err,
    )

  proc init2*(
      T: type VNodeHelper, studioRef: ref Studio, rootId: cstring
  ): tuple[main, replay: VNodeHelper] {.inline.} =
    let
      mobile = isMobile()
      mainRootId = "pon2-studio-main-" & rootId
      replayRootId = "pon2-studio-replay-" & rootId

    (
      main: VNodeHelper(
        mobile: mobile,
        simulator: SimulatorVNodeHelper.init(studioRef[].simulator, mainRootId),
        studioOpt: Opt[StudioVNodeHelper].ok StudioVNodeHelper.init(
          mainRootId, isReplaySimulator = false
        ),
      ),
      replay: VNodeHelper(
        mobile: mobile,
        simulator: SimulatorVNodeHelper.init(studioRef[].replaySimulator, replayRootId),
        studioOpt: Opt[StudioVNodeHelper].ok StudioVNodeHelper.init(
          replayRootId, isReplaySimulator = true
        ),
      ),
    )

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

    "{AssetsDir}/noticegarbage/{stem}.png".fmt.cstring
  {.pop.}
