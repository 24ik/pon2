## This module implements simulator views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[ctrl, field, goal, msg, next, operating, palette, setting, share, step]
import ../../[app]

when defined(js) or defined(nimsuggest):
  import std/[jsffi]
  import karax/[karaxdsl, vdom, vstyles]
  import ../../[core]

type SimulatorView* = object ## View of the simulator.
  simulator: ref Simulator

  ctrl: CtrlView
  field: FieldView
  goal: GoalView
  msg: MsgView
  nexts: NextsView
  operating: OperatingView
  palette: PaletteView
  settings: SettingsView
  share: ShareView
  steps: StepsView

  cameraReadyField: FieldView
  cameraReadyGoal: GoalView
  cameraReadySteps: StepsView

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type SimulatorView, simulator: ref Simulator, showCursor = true
): T {.inline.} =
  T(
    simulator: simulator,
    ctrl: CtrlView.init simulator,
    field: FieldView.init(simulator, showCursor),
    goal: GoalView.init simulator,
    msg: MsgView.init simulator,
    nexts: NextsView.init simulator,
    operating: OperatingView.init simulator,
    palette: PaletteView.init simulator,
    settings: SettingsView.init simulator,
    share: ShareView.init simulator,
    steps: StepsView.init(simulator, showCursor),
    cameraReadyField: FieldView.init(simulator, showCursor),
    cameraReadyGoal: GoalView.init simulator,
    cameraReadySteps: StepsView.init(simulator, showCursor),
  )

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const
    GoalIdPrefix = "pon2-simulator-goal-".cstring
    CameraReadyIdPrefix = "pon2-simulator-cameraready-".cstring

  proc toVNode*(self: SimulatorView, id: cstring): VNode {.inline.} =
    ## Returns the simulator node.
    let cameraReadyId = CameraReadyIdPrefix & id

    buildHtml tdiv:
      if self.simulator[].nazoPuyoWrap.optGoal.isOk:
        tdiv(class = "block"):
          self.goal.toVNode GoalIdPrefix & id
      tdiv(class = "block"):
        tdiv(class = "columns is-mobile is-variable is-1"):
          tdiv(class = "column is-narrow"):
            if self.simulator[].mode notin EditModes:
              tdiv(class = "block"):
                self.operating.toVNode
            tdiv(class = "block"):
              self.field.toVNode
            tdiv(class = "block"):
              self.msg.toVNode
            if self.simulator[].mode != Replay:
              tdiv(class = "block"):
                self.settings.toVNode
            tdiv(class = "block"):
              self.share.toVNode cameraReadyId
          if self.simulator[].mode notin EditModes:
            tdiv(class = "column is-narrow"):
              tdiv(class = "block"):
                self.nexts.toVNode
          tdiv(class = "column is-narrow"):
            tdiv(class = "block"):
              self.ctrl.toVNode
            if self.simulator[].mode in EditModes:
              tdiv(class = "block"):
                self.palette.toVNode
            tdiv(class = "block"):
              self.steps.toVNode
      tdiv(
        id = cameraReadyId,
        style = style(
          (StyleAttr.display, "none".cstring), (StyleAttr.width, "fit-content".cstring)
        ),
      ):
        if self.simulator[].nazoPuyoWrap.optGoal.isOk:
          tdiv(class = "block"):
            self.cameraReadyGoal.toVNode("", cameraReady = true)
        tdiv(class = "block"):
          tdiv(class = "columns is-mobile is-variable is-1"):
            tdiv(class = "column is-narrow"):
              tdiv(class = "block"):
                self.cameraReadyField.toVNode(cameraReady = true)
              tdiv(class = "block"):
                self.msg.toVNode
            tdiv(class = "column is-narrow"):
              self.cameraReadySteps.toVNode(cameraReady = true)
