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
  import ../../[app, core]
  import ../../private/[dom, gui, utils]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  proc toGoalVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, cameraReady = false
  ): VNode =
    ## Returns the goal node.
    let goal = self.derefSimulator(helper).nazoPuyo.goal

    if cameraReady or self.derefSimulator(helper).mode != EditorEdit:
      return buildHtml article(
        class = (
          if helper.simulator.markResult == Correct: "message is-success"
          else: "message is-info"
        ).kstring
      ):
        tdiv(class = "message-body"):
          text ($goal).kstring
          if helper.simulator.markResult == Correct:
            span(class = "icon"):
              italic(class = "fa-solid fa-circle-check")

    let
      kindId = ("pon2-simulator-goal-kind-" & helper.simulator.goalId).kstring
      colorId = ("pon2-simulator-goal-color-" & helper.simulator.goalId).kstring
      valId = ("pon2-simulator-goal-val-" & helper.simulator.goalId).kstring
      clearColorId =
        ("pon2-simulator-goal-clearcolor-" & helper.simulator.goalId).kstring

    buildHtml tdiv:
      tdiv(class = "block mb-1"):
        tdiv(class = "select"):
          select(
            id = kindId,
            onchange =
              () => (
                block:
                  let index = kindId.getSelectedIndex
                  self.derefSimulator(helper).goalKindOpt =
                    if index == 0:
                      Opt[GoalKind].err
                    else:
                      Opt[GoalKind].ok index.pred.GoalKind
              ),
          ):
            option(selected = goal.mainOpt.isErr):
              text "メイン条件未設定"
            for kind in GoalKind:
              option(
                selected = goal.mainOpt.isOk and goal.mainOpt.unsafeValue.kind == kind
              ):
                text ($kind).kstring
      if goal.mainOpt.isOk:
        let main = goal.mainOpt.unsafeValue

        tdiv(class = "block mb-1"):
          if main.kind in ColorKinds:
            button(class = "button is-static px-2"):
              text "c ="
            tdiv(class = "select"):
              select(
                id = colorId,
                onchange =
                  () => (
                    self.derefSimulator(helper).goalColor =
                      colorId.getSelectedIndex.GoalColor
                  ),
              ):
                option(selected = main.color == All):
                  text "全"
                for color in GoalColor.All.succ .. GoalColor.high:
                  option(selected = main.color == color):
                    text ($color).kstring
        tdiv(class = "block mb-1"):
          button(class = "button is-static px-2"):
            text "n ="
          tdiv(class = "select"):
            select(
              id = valId,
              onchange =
                () => (self.derefSimulator(helper).goalVal = valId.getSelectedIndex),
            ):
              for val in 0 .. 99:
                option(selected = main.val == val):
                  text ($val).kstring
          button(
            class = "button px-2",
            onclick =
              () => (
                self.derefSimulator(helper).goalOperator = main.operator.rotateSucc
              ),
          ):
            text ($main.operator).kstring
      tdiv(class = "block"):
        tdiv(class = "select"):
          select(
            id = clearColorId,
            disabled = goal.clearColorOpt.isErr,
            onchange =
              () => (
                self.derefSimulator(helper).goalClearColorOpt =
                  Opt[GoalColor].ok clearColorId.getSelectedIndex.GoalColor
              ),
          ):
            option(selected = goal.clearColorOpt == Opt[GoalColor].ok All):
              text "全"
            for color in GoalColor.All.succ .. GoalColor.high:
              option(selected = goal.clearColorOpt == Opt[GoalColor].ok color):
                text ($color).kstring
        button(
          class = "button px-2",
          onclick =
            () => (
              block:
                if goal.clearColorOpt.isOk:
                  self.derefSimulator(helper).goalClearColorOpt = Opt[GoalColor].err
                else:
                  self.derefSimulator(helper).goalClearColorOpt =
                    Opt[GoalColor].ok GoalColor.low
            ),
        ):
          if goal.clearColorOpt.isOk:
            text "ぷよ全て消す"
          else:
            strikethrough:
              text "ぷよ全て消す"
