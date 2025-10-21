## This module implements IDE views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[ctrl, pagination, setting]
import ../[simulator]
import ../../[app]

when defined(js) or defined(nimsuggest):
  import std/[jsffi, strformat]
  import karax/[karaxdsl, vdom]
  import ../../private/[gui]

type IdeView* = object ## View of the IDE.
  ide: ref Ide

  simulator: SimulatorView
  replaySimulator: SimulatorView

  ctrl: IdeCtrlView
  pagination: IdePaginationView
  setting: IdeSettingView

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type IdeView, ide: ref Ide, showCursor = true): T {.inline.} =
  T(
    ide: ide,
    simulator: SimulatorView.init(ide[].simulator, showCursor),
    replaySimulator: SimulatorView.init(ide[].replaySimulator, showCursor),
    ctrl: IdeCtrlView.init ide,
    pagination: IdePaginationView.init ide,
    setting: IdeSettingView.init ide,
  )

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const
    SimulatorIdPrefix = "pon2-ide-mainsimulator-"
    ReplaySimulatorIdPrefix = "pon2-ide-replaysimulator-"
    SettingIdPrefix = "pon2-ide-setting-"

  proc toVNode*(self: IdeView, id: cstring): VNode {.inline.} =
    ## Returns the IDE node.
    let settingId = "{SettingIdPrefix}{id}".fmt.cstring

    buildHtml tdiv(class = "columns is-1"):
      tdiv(class = "column is-narrow"):
        section(class = (if isMobile(): "section pt-3 pl-3" else: "section").cstring):
          self.simulator.toVNode "{SimulatorIdPrefix}{id}".fmt.cstring
      if self.ide[].simulator[].mode in EditorModes and
          self.ide[].simulator[].nazoPuyoWrap.optGoal.isOk:
        tdiv(class = "column is-narrow"):
          section(class = "section"):
            tdiv(class = "block"):
              self.ctrl.toVNode settingId
            tdiv(class = "block"):
              self.setting.toVNode settingId
            tdiv(class = "block"):
              self.pagination.toVNode
            if self.ide[].replayStepsCnt > 0:
              tdiv(class = "block"):
                self.replaySimulator.toVNode "{ReplaySimulatorIdPrefix}{id}".fmt.cstring
