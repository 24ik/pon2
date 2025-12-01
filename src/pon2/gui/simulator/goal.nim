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

  export vdom

  proc toGoalVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, cameraReady = false
  ): VNode =
    ## Returns the goal node.
    let goal = self.derefSimulator(helper).nazoPuyoWrap.unwrap:
      it.goal

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
                text $kind
      if goal.mainOpt.isOk:
        let
          main = goal.mainOpt.unsafeValue
          atLeastBtnClass = (
            case main.valOperator
            of Exact: "button px-2"
            of AtLeast: "button is-primary px-2"
          ).cstring

        tdiv(class = "block"):
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
                    text $color
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
                  text $val
          button(
            class = atLeastBtnClass,
            onclick =
              () => (
                self.derefSimulator(helper).goalValOperator =
                  (1 - main.valOperator.ord).GoalValOperator
              ),
          ):
            text "以上"
      tdiv(class = "block"):
        discard
