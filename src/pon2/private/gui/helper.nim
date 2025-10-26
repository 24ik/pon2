## This module implements helpers for making GUI.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import std/[jsffi, strformat]
  import ../[utils]
  import ../../[app]

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

  func init*(
      T: type SimulatorVNodeHelper, simulator: Simulator, rootId: cstring
  ): T {.inline.} =
    T(
      goalId: "pon2-simulator-goal-" & rootId,
      cameraReadyId: "pon2-simulator-cameraready-" & rootId,
      markResultOpt: simulator.mark,
    )

  func init*(
      T: type StudioVNodeHelper, rootId: cstring, isReplaySimulator: bool
  ): T {.inline.} =
    T(settingId: "pon2-studio-setting-" & rootId, isReplaySimulator: isReplaySimulator)
