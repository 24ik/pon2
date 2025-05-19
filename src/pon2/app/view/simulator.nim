## This module implements simulator views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import karax/[karaxdsl, vdom, vstyles]
  import ./[ctrl, field, goal, msg, next, operating, palette, setting, share, step]
  import ../[nazopuyowrap, simulator]
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

  displayField: FieldView
  displayGoal: GoalView
  displaySteps: StepsView

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type SimulatorView, simulator: ref Simulator): T {.inline.} =
  let enableCursor =
    when defined(js):
      not isMobile()
    else:
      true

  T(
    ctrl: CtrlView.init simulator,
    field: FieldView.init(simulator, enableCursor),
    goal: Goal.init simulator,
    msg: MsgView.init simulator,
    nexts: NextsView.init simulator,
    operating: OperatingView.init simulator,
    palette: PaletteView.init simulator,
    settings: SettingsView.init simulator,
    share: ShareView.init simulator,
    steps: StepsView.init(simulator, enableCursor),
    displayField: FieldView.init(simulator, enableCursor, true),
    displayGoal: GoalView.init(simulator, true),
    displaySteps: StepsView.init(simulator, enableCursor, true),
  )

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const DisplayNodeIdPrefix = "pon2-simulator-display-"

  proc toVNode*(self: SimulatorView, id: string): VNode {.inline.} =
    ## Returns the simulator node.
    let displayNodeId = (DisplayNodeIdPrefix & id).cstring

    buildHtml tdiv:
      if self.simulator[].nazoPuyoWrap.optGoal.isOk:
        tdiv(class = "block"):
          self.goal.toVNode
      tdiv(class = "block"):
        tdiv(class = "columns is-mobile is-variable is-1"):
          tdiv(class = "column is-narrow"):
            if self.simulator[].mode notin EditModes:
              tdiv(class = "block"):
                self.operating.toVNode
            tdiv(class = "block"):
              self.field.toVNode
            if self.simulator[].mode != EditorEdit:
              tdiv(class = "block"):
                self.msg.toVNode
            if self.simulator[].mode == EditorEdit:
              tdiv(class = "block"):
                self.settings.toVNode
            tdiv(class = "block"):
              self.share.toVNode displayNodeId
          if self.simulator[].mode != EditorEdit:
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
      tdiv(id = displayNodeId, style = style(StyleAttr.display, "none")):
        if self.simulator[].nazoPuyoWrap.optGoal.isOk:
          tdiv(class = "block"):
            self.displayGoal.toVNode
        tdiv(class = "block"):
          tdiv(class = "columns is-mobile is-variable is-1"):
            tdiv(class = "column is-narrow"):
              self.displayField.toVNode
            tdiv(class = "column is-narrow"):
              self.displaySteps.toVNode
