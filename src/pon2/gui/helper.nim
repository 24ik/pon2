## This module implements helpers for making GUI.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[jsffi, jsre]
  import karax/[kdom, vdom]
  import ../[app]
  import ../private/gui/[helper]

  type VNodeHelper* = object ## Helper for making VNode.
    mobile*: bool
    simulator*: SimulatorVNodeHelper
    studioOpt*: Opt[StudioVNodeHelper]

  proc isMobile(): bool {.inline.} =
    ## Returns `true` if a mobile device is detected.
    r"iPhone|Android.+Mobile".newRegExp in navigator.userAgent

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
