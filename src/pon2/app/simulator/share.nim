## This module implements share views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karax, karaxdsl, kdom, vdom]
  import ../[nazopuyowrap, simulator]
  import ../../[core]

type ShareView* = object ## View of the share.
  simulator: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type ShareView, simulator: ref Simulator): T {.inline.} =
  T(simulator: simulator)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  proc toVNode*(self: ShareView): VNode {.inline.} =
    ## Returns the share node.
    let goal = self.simulator[].nazoPuyoWrap.optGoal.unsafeValue

    if self.displayMode or self.simulator[].mode != EditorEdit:
      return buildHtml bold:
        text $goal

    # kind node
    let kindNode = buildHtml tdiv(class = "select"):
      select:
        for kind in GoalKind:
          option(selected = kind == goal.kind):
            text $kind
    kindNode[0].addEventListener onchange,
      (ev: Event, target: VNode) => (
        self.simulator[].goalKind =
          cast[Element](kindNode[0].dom).selectedOptions[0].selectedIndex.GoalKind
      )

    # color node
    let colorNode: VNode
    if goal.kind in ColorKinds:
      colorNode = buildHtml tdiv:
        button(class = "button is-static px-2"):
          text "c ="
        tdiv(class = "select"):
          select:
            option(selected = goal.optColor.unsafeValue == All):
              text "全"
            for color in GoalColor.All.succ .. GoalColor.high:
              option(selected = color == goal.optColor.unsafeValue):
                text $color
      colorNode[1].addEventListener onchange,
        (ev: Event, target: VNode) => (
          self.simulator[].goalColor =
            cast[Element](kindNode[1].dom).selectedOptions[1].selectedIndex.GoalColor
        )
    else:
      colorNode = nil

    # val node
    let valNode: VNode
    if goal.kind in ValKinds:
      valNode = buildHtml tdiv:
        button(class = "button is-static px-2"):
          text "n ="
        tdiv(class = "select"):
          select:
            for val in 0 .. 99:
              option(selected = val == goal.optVal.unsafeValue):
                text $val
      valNode[1].addEventListener onchange,
        (ev: Event, target: VNode) => (
          self.simulator[].goalVal =
            cast[Element](kindNode[1].dom).selectedOptions[1].selectedIndex.GoalVal
        )
    else:
      valNode = nil

    buildHtml tdiv:
      tdiv(class = "block mb-1"):
        kindNode
      tdiv(class = "block"):
        if not colorNode.isNil:
          colorNode
        if not valNode.isNil:
          valNode
