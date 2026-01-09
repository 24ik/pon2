## This module implements helpers for making views.
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
  import ../private/[dom, strutils, utils]

  export app, kbase

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

    GrimoireVNodeHelper* = object ## Helper for making VNode of grimoire.
      searchId*: kstring
      exportId*: kstring
      importId*: kstring
      matcher*: GrimoireMatcher
      matchSolvedOpt*: Opt[bool]
      matchedEntryIndices*: seq[int16]
      solvedEntryIndices*: set[int16]
      pageIndex*: int

    VNodeHelper* = object ## Helper for making VNode.
      mobile*: bool
      simulator*: SimulatorVNodeHelper
      studioOpt*: Opt[StudioVNodeHelper]
      marathonOpt*: Opt[MarathonVNodeHelper]
      grimoireOpt*: Opt[GrimoireVNodeHelper]

  func init(T: type SimulatorVNodeHelper, simulator: Simulator, rootId: kstring): T =
    T(
      goalId: "pon2-simulator-goal-" & rootId,
      cameraReadyId: "pon2-simulator-cameraready-" & rootId,
      markResult: if simulator.mode in EditModes: Incorrect else: simulator.mark,
    )

  func init(T: type StudioVNodeHelper, rootId: kstring, isReplaySimulator: bool): T =
    T(settingId: "pon2-studio-setting-" & rootId, isReplaySimulator: isReplaySimulator)

  func init(T: type MarathonVNodeHelper, rootId: kstring): T =
    T(searchBarId: "pon2-marathon-searchbar-" & rootId)

  func init(
      T: type GrimoireVNodeHelper,
      rootId: kstring,
      matcher: GrimoireMatcher,
      matchSolvedOpt: Opt[bool],
      matchedEntryIndices: seq[int16],
      solvedEntryIndices: set[int16],
      pageIndex: int,
  ): T =
    T(
      searchId: "pon2-grimoire-search-" & rootId,
      exportId: "pon2-grimoire-export-" & rootId,
      importId: "pon2-grimoire-import-" & rootId,
      matcher: matcher,
      matchSolvedOpt: matchSolvedOpt,
      matchedEntryIndices: matchedEntryIndices,
      solvedEntryIndices: solvedEntryIndices,
      pageIndex: pageIndex,
    )

  proc init*(T: type VNodeHelper, simulatorRef: ref Simulator, rootId: kstring): T =
    VNodeHelper(
      mobile: mobileDetected(),
      simulator: SimulatorVNodeHelper.init(simulatorRef[], rootId),
      studioOpt: Opt[StudioVNodeHelper].err,
      marathonOpt: Opt[MarathonVNodeHelper].err,
      grimoireOpt: Opt[GrimoireVNodeHelper].err,
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
        grimoireOpt: Opt[GrimoireVNodeHelper].err,
      ),
      replay: VNodeHelper(
        mobile: mobile,
        simulator: SimulatorVNodeHelper.init(studioRef[].replaySimulator, replayRootId),
        studioOpt: Opt[StudioVNodeHelper].ok StudioVNodeHelper.init(
          replayRootId, isReplaySimulator = true
        ),
        marathonOpt: Opt[MarathonVNodeHelper].err,
        grimoireOpt: Opt[GrimoireVNodeHelper].err,
      ),
    )

  proc init*(T: type VNodeHelper, marathonRef: ref Marathon, rootId: kstring): T =
    VNodeHelper(
      mobile: mobileDetected(),
      simulator: SimulatorVNodeHelper.init(marathonRef[].simulator, rootId),
      studioOpt: Opt[StudioVNodeHelper].err,
      marathonOpt: Opt[MarathonVNodeHelper].ok MarathonVNodeHelper.init rootId,
      grimoireOpt: Opt[GrimoireVNodeHelper].err,
    )

  proc init*(
      T: type VNodeHelper,
      grimoireRef: ref Grimoire,
      rootId: kstring,
      matcher: GrimoireMatcher,
      matchSolvedOpt: Opt[bool],
      matchedEntryIndices: seq[int16],
      solvedEntryIndices: set[int16],
      pageIndex: int,
  ): T =
    VNodeHelper(
      mobile: mobileDetected(),
      simulator: SimulatorVNodeHelper.init(grimoireRef[].simulator, rootId),
      studioOpt: Opt[StudioVNodeHelper].err,
      marathonOpt: Opt[MarathonVNodeHelper].err,
      grimoireOpt: Opt[GrimoireVNodeHelper].ok GrimoireVNodeHelper.init(
        rootId, matcher, matchSolvedOpt, matchedEntryIndices, solvedEntryIndices,
        pageIndex,
      ),
    )
