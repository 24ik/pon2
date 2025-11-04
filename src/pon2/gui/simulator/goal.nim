## This module implements goal views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[jsffi, sugar]
  import karax/[karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[gui, utils]

  proc toGoalVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, cameraReady = false
  ): VNode {.inline.} =
    ## Returns the goal node.
    let goal = self.derefSimulator(helper).nazoPuyoWrap.optGoal.unsafeValue

    if cameraReady or self.derefSimulator(helper).mode != EditorEdit:
      return buildHtml article(
        class = (
          if helper.simulator.markResultOpt.unsafeValue == Accept: "message is-success"
          else: "message is-info"
        ).cstring
      ):
        tdiv(class = "message-body"):
          text $goal
          if helper.simulator.markResultOpt.unsafeValue == Accept:
            span(class = "icon"):
              italic(class = "fa-solid fa-circle-check")

    let
      kindId = "pon2-simulator-goal-kind-" & helper.simulator.goalId
      colorId = "pon2-simulator-goal-color-" & helper.simulator.goalId
      valId = "pon2-simulator-goal-val-" & helper.simulator.goalId

    buildHtml tdiv:
      tdiv(class = "block mb-1"):
        tdiv(class = "select"):
          select(
            id = kindId,
            onchange =
              () =>
              (self.derefSimulator(helper).goalKind = kindId.getSelectedIdx.GoalKind),
          ):
            for kind in GoalKind:
              option(selected = kind == goal.kind):
                text $kind
      tdiv(class = "block"):
        if goal.kind in ColorKinds:
          button(class = "button is-static px-2"):
            text "c ="
          tdiv(class = "select"):
            select(
              id = colorId,
              onchange =
                () => (
                  self.derefSimulator(helper).goalColor =
                    colorId.getSelectedIdx.GoalColor
                ),
            ):
              option(selected = goal.optColor.unsafeValue == All):
                text "全"
              for color in GoalColor.All.succ .. GoalColor.high:
                option(selected = color == goal.optColor.unsafeValue):
                  text $color
        if goal.kind in ValKinds:
          button(class = "button is-static px-2"):
            text "n ="
          tdiv(class = "select"):
            select(
              id = valId,
              onchange =
                () =>
                (self.derefSimulator(helper).goalVal = valId.getSelectedIdx.GoalVal),
            ):
              for val in 0 .. 99:
                option(selected = val == goal.optVal.unsafeValue):
                  text $val
