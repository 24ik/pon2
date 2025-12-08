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
  import std/[jsffi]
  import karax/[kbase, vdom]
  import ../[app]
  import ../private/[dom, results2, utils]

  export kbase, results2

  type
    SimulatorVNodeHelper* = object ## Helper for making VNode of simulators.
      goalId*: kstring
      cameraReadyId*: kstring
      markResult*: MarkResult

    StudioVNodeHelper* = object ## Helper for making VNode of studios.
      isReplaySimulator*: bool
      settingId*: kstring

    MarathonVNodeHelper* = object ## Helper for making VNode of marathon.
      searchBarId*: kstring

    VNodeHelper* = object ## Helper for making VNode.
      mobile*: bool
      simulator*: SimulatorVNodeHelper
      studioOpt*: Opt[StudioVNodeHelper]
      marathonOpt*: Opt[MarathonVNodeHelper]

  func init(T: type SimulatorVNodeHelper, simulator: Simulator, rootId: kstring): T =
    T(
      goalId: "pon2-simulator-goal-" & rootId,
      cameraReadyId: "pon2-simulator-cameraready-" & rootId,
      markResult: simulator.mark,
    )

  func init(T: type StudioVNodeHelper, rootId: kstring, isReplaySimulator: bool): T =
    T(settingId: "pon2-studio-setting-" & rootId, isReplaySimulator: isReplaySimulator)

  func init(T: type MarathonVNodeHelper, rootId: kstring): T =
    T(searchBarId: "pon2-marathon-searchbar-" & rootId)

  proc init*(T: type VNodeHelper, simulatorRef: ref Simulator, rootId: kstring): T =
    VNodeHelper(
      mobile: mobileDetected(),
      simulator: SimulatorVNodeHelper.init(simulatorRef[], rootId),
      studioOpt: Opt[StudioVNodeHelper].err,
      marathonOpt: Opt[MarathonVNodeHelper].err,
    )

  proc init2*(
      T: type VNodeHelper, studioRef: ref Studio, rootId: kstring
  ): tuple[main, replay: VNodeHelper] =
    let
      mobile = mobileDetected()
      mainRootId = "pon2-studio-main-" & rootId
      replayRootId = "pon2-studio-replay-" & rootId

    (
      main: VNodeHelper(
        mobile: mobile,
        simulator: SimulatorVNodeHelper.init(studioRef[].simulator, mainRootId),
        studioOpt: Opt[StudioVNodeHelper].ok StudioVNodeHelper.init(
          mainRootId, isReplaySimulator = false
        ),
        marathonOpt: Opt[MarathonVNodeHelper].err,
      ),
      replay: VNodeHelper(
        mobile: mobile,
        simulator: SimulatorVNodeHelper.init(studioRef[].replaySimulator, replayRootId),
        studioOpt: Opt[StudioVNodeHelper].ok StudioVNodeHelper.init(
          replayRootId, isReplaySimulator = true
        ),
        marathonOpt: Opt[MarathonVNodeHelper].err,
      ),
    )

  proc init*(T: type VNodeHelper, marathonRef: ref Marathon, rootId: kstring): T =
    VNodeHelper(
      mobile: mobileDetected(),
      simulator: SimulatorVNodeHelper.init(marathonRef[].simulator, rootId),
      studioOpt: Opt[StudioVNodeHelper].err,
      marathonOpt: Opt[MarathonVNodeHelper].ok MarathonVNodeHelper.init rootId,
    )
