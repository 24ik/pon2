## This module implements goal views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../[app]

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karax, karaxdsl, vdom]
  import ../../[core]
  import ../../private/[utils]

type GoalView* = object ## View of the goal.
  simulator: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type GoalView, simulator: ref Simulator): T {.inline.} =
  T(simulator: simulator)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const
    KindIdPrefix = "pon2-simulator-goal-kind-".cstring
    ColorIdPrefix = "pon2-simulator-goal-color-".cstring
    ValIdPrefix = "pon2-simulator-goal-val-".cstring

  proc toVNode*(self: GoalView, id: cstring, cameraReady = false): VNode {.inline.} =
    ## Returns the goal node.
    ## `id` is not used if `cameraReady` is `true`; otherwise `id` should be unique.
    let
      goal = self.simulator[].nazoPuyoWrap.optGoal.unsafeValue
      accepted = self.simulator[].mark == Accept

    if cameraReady or self.simulator[].mode != EditorEdit:
      return buildHtml article(
        class = (if accepted: "message is-success" else: "message is-info").cstring
      ):
        tdiv(class = "message-body"):
          text $goal
          if accepted:
            span(class = "icon"):
              italic(class = "fa-solid fa-circle-check")

    let
      kindId = KindIdPrefix & id
      colorId = ColorIdPrefix & id
      valId = ValIdPrefix & id

    buildHtml tdiv:
      tdiv(class = "block mb-1"):
        tdiv(class = "select"):
          select(
            id = kindId,
            onchange =
              () => (self.simulator[].goalKind = kindId.getSelectedIdx.GoalKind),
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
                () => (self.simulator[].goalColor = colorId.getSelectedIdx.GoalColor),
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
              onchange = () => (self.simulator[].goalVal = valId.getSelectedIdx.GoalVal),
            ):
              for val in 0 .. 99:
                option(selected = val == goal.optVal.unsafeValue):
                  text $val
