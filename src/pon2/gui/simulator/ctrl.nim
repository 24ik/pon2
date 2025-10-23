## This module implements controller views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../[app]

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karax, karaxdsl, vdom, vstyles]
  import ../../private/[gui]

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
  proc toSideVNode*(self: CtrlView): VNode {.inline.} =
    ## Returns the controller node replaced next the field.
    let
      mobile = isMobile()
      insertBtnCls = (
        if self.simulator[].editData.insert: "button is-primary" else: "button"
      ).cstring
      fieldStyle =
        if mobile:
          style(StyleAttr.columnGap, "0.5em")
        else:
          style()

    buildHtml tdiv(class = "card", style = translucentStyle):
      tdiv(class = "card-content p-1"):
        case self.simulator[].mode
        of EditorEdit:
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].undo):
                text "Undo"
                if not mobile:
                  span(style = counterStyle):
                    text "Sft+Z"
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].redo):
                text "Redo"
                if not mobile:
                  span(style = counterStyle):
                    text "Sft+Y"
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].reset):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-fast")
                  if not mobile:
                    span(style = counterStyle):
                      text "Z"
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].backward):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-step")
                  if not mobile:
                    span(style = counterStyle):
                      text "X"
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].forward):
                span(class = "icon"):
                  italic(class = "fa-solid fa-forward-step")
                  if not mobile:
                    span(style = counterStyle):
                      text "C"
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(
                class = insertBtnCls, onclick = () => self.simulator[].toggleInsert
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-indent")
                  if not mobile:
                    span(style = counterStyle):
                      text "I"
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].shiftFieldUp):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-up")
                  if not mobile:
                    span(style = counterStyle):
                      text "Sft+W"
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.simulator[].flipFieldHorizontal
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-right-left")
                  if not mobile:
                    span(style = counterStyle):
                      text "F"
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].shiftFieldLeft):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-left")
                  if not mobile:
                    span(style = counterStyle):
                      text "Sft+A"
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].shiftFieldDown):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-down")
                  if not mobile:
                    span(style = counterStyle):
                      text "Sft+S"
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].shiftFieldRight):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-right")
                  if not mobile:
                    span(style = counterStyle):
                      text "Sft+D"
        of ViewerEdit, Replay:
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].reset):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-fast")
                  if not mobile:
                    span(style = counterStyle):
                      text "Z"
            tdiv(class = "control", style = fieldStyle):
              button(class = "button", onclick = () => self.simulator[].backward):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-step")
                  if not mobile:
                    span(style = counterStyle):
                      text "X"
            tdiv(class = "control", style = fieldStyle):
              button(class = "button", onclick = () => self.simulator[].forward):
                span(class = "icon"):
                  italic(class = "fa-solid fa-forward-step")
                  if not mobile:
                    span(style = counterStyle):
                      text "C"
        of PlayModes:
          if mobile:
            tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
              tdiv(class = "control"):
                button(class = "button", onclick = () => self.simulator[].reset):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-backward-fast")
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.simulator[].forward(skip = true),
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-angles-right")
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.simulator[].forward(replay = true),
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-forward-step")
          else:
            tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
              tdiv(class = "control"):
                button(class = "button", onclick = () => self.simulator[].reset):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-backward-fast")
                    span(style = counterStyle):
                      text "Z"
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.simulator[].forward(skip = true),
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-angles-right")
                    span(style = counterStyle):
                      text "Space"
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.simulator[].forward(replay = true),
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-forward-step")
                    span(style = counterStyle):
                      text "C"
            tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
              tdiv(class = "control"):
                button(
                  class = "button", onclick = () => self.simulator[].rotatePlacementLeft
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-rotate-left")
                    span(style = counterStyle):
                      text "J"
              tdiv(class = "control"):
                button(class = "button", onclick = () => self.simulator[].backward):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-up")
                    span(style = counterStyle):
                      text "W"
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.simulator[].rotatePlacementRight,
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-rotate-right")
                    span(style = counterStyle):
                      text "K"
            tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
              tdiv(class = "control"):
                button(
                  class = "button", onclick = () => self.simulator[].movePlacementLeft
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-left")
                    span(style = counterStyle):
                      text "A"
              tdiv(class = "control"):
                button(class = "button", onclick = () => self.simulator[].forward):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-down")
                    span(style = counterStyle):
                      text "S"
              tdiv(class = "control"):
                button(
                  class = "button", onclick = () => self.simulator[].movePlacementRight
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-right")
                    span(style = counterStyle):
                      text "D"

  proc toBottomVNode*(self: CtrlView): VNode {.inline.} =
    ## Returns the controller node replaced bottom of the window.
    buildHtml tdiv(class = "card", style = translucentStyle):
      tdiv(class = "card-content p-1"):
        case self.simulator[].mode
        of PlayModes:
          tdiv(class = "field is-grouped is-grouped-centered"):
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.simulator[].rotatePlacementLeft
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-rotate-left")
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].backward):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-up")
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.simulator[].rotatePlacementRight
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-rotate-right")
          tdiv(class = "field is-grouped is-grouped-centered"):
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.simulator[].movePlacementLeft
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-left")
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].forward):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-down")
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.simulator[].movePlacementRight
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-right")
        of ViewerEdit:
          tdiv(class = "field is-grouped is-grouped-is-centered mb-0"):
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].backward):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-step")
          tdiv(class = "field is-grouped is-grouped-is-centered"):
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.simulator[].forward):
                span(class = "icon"):
                  italic(class = "fa-solid fa-forward-step")
        of EditorEdit, Replay:
          discard
