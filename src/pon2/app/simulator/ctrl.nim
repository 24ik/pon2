## This module implements controller views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karax, karaxdsl, vdom]
  import ../[simulator]

type CtrlView* = object ## View of the controller.
  simulator: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type CtrlView, simulator: ref Simulator): T {.inline.} =
  T(simulator: simulator)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const SelectBtnCls = "button is-selected is-primary".cstring

  proc toVNode*(self: CtrlView): VNode {.inline.} =
    ## Returns the controller node.
    let insertBtnCls = if self.simulator[].editData.insert: SelectBtnCls else: "button"

    buildHtml tdiv:
      case self.simulator[].mode
      of PlayModes:
        tdiv(class = "buttons is-centered mb-3"):
          button(
            class = "button is-light",
            onclick = () => self.simulator[].backward(detail = true),
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-caret-left")
          button(
            class = "button is-light",
            onclick = () => self.simulator[].forward(skip = true),
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-angles-down")
        tdiv(class = "buttons is-centered mb-3"):
          button(class = "button is-light", onclick = () => self.simulator[].reset):
            span(class = "icon"):
              italic(class = "fa-solid fa-backward-fast")
          button(class = "button is-light", onclick = () => self.simulator[].backward):
            span(class = "icon"):
              italic(class = "fa-solid fa-backward-step")
          button(
            class = "button is-light",
            onclick = () => self.simulator[].forward(replay = true),
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-forward-step")
        tdiv(class = "buttons is-centered mb-3"):
          button(
            class = "button is-info",
            onclick = () => self.simulator[].rotatePlacementLeft,
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-arrow-rotate-left")
          button(class = "button is-light", onclick = () => self.simulator[].backward):
            span(class = "icon"):
              italic(class = "fa-solid fa-backward-step")
          button(
            class = "button is-info",
            onclick = () => self.simulator[].rotatePlacementRight,
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-arrow-rotate-right")
        tdiv(class = "buttons is-centered mb-3"):
          button(
            class = "button is-info", onclick = () => self.simulator[].movePlacementLeft
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-arrow-left")
          button(class = "button is-info", onclick = () => self.simulator[].forward):
            span(class = "icon"):
              italic(class = "fa-solid fa-arrow-down")
          button(
            class = "button is-info",
            onclick = () => self.simulator[].movePlacementRight,
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-arrow-right")
      of EditModes:
        tdiv(class = "buttons is-centered mb-3"):
          button(class = insertBtnCls, onclick = () => self.simulator[].toggleInsert):
            span(class = "icon"):
              italic(class = "fa-solid fa-indent")
          button(
            class = "button is-light",
            onclick = () => self.simulator[].flipFieldHorizontal,
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-arrow-right-arrow-left")
          button(class = "button is-light", onclick = () => self.simulator[].undo):
            span(class = "icon"):
              italic(class = "fa-solid fa-circle-arrow-left")
          button(class = "button is-light", onclick = () => self.simulator[].redo):
            span(class = "icon"):
              italic(class = "fa-solid fa-circle-arrow-right")
        tdiv(class = "buttons is-centered"):
          button(
            class = "button is-light", onclick = () => self.simulator[].shiftFieldLeft
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-angles-left")
          button(
            class = "button is-light", onclick = () => self.simulator[].shiftFieldDown
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-angles-down")
          button(
            class = "button is-light", onclick = () => self.simulator[].shiftFieldUp
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-angles-up")
          button(
            class = "button is-light", onclick = () => self.simulator[].shiftFieldRight
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-angles-right")
      of Replay:
        tdiv(class = "buttons is-centered mb-3"):
          button(class = "button is-light", onclick = () => self.simulator[].reset):
            span(class = "icon"):
              italic(class = "fa-solid fa-backward-fast")
          button(
            class = "button is-light",
            onclick = () => self.simulator[].backward(detail = true),
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-caret-left")
        tdiv(class = "buttons is-centered mb-3"):
          button(class = "button is-light", onclick = () => self.simulator[].backward):
            span(class = "icon"):
              italic(class = "fa-solid fa-backward-step")
          button(
            class = "button is-light",
            onclick = () => self.simulator[].forward(replay = true),
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-forward-step")
