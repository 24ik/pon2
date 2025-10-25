## This module implements controller views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karaxdsl, vdom, vstyles]
  import ../../[app]
  import ../../private/[gui]

  proc toSideCtrlVNode*[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper
  ): VNode {.inline.} =
    ## Returns the controller node replaced next the field.
    let
      insertBtnCls = (
        if self.derefSimulator(helper).editData.insert: "button is-primary"
        else: "button"
      ).cstring
      fieldStyle =
        if helper.mobile:
          style(StyleAttr.columnGap, "0.5em")
        else:
          style()

    buildHtml tdiv(class = "card", style = translucentStyle):
      tdiv(class = "card-content p-1"):
        case self.derefSimulator(helper).mode
        of EditorEdit:
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.derefSimulator(helper).undo):
                text "Undo"
                if not helper.mobile:
                  span(style = counterStyle):
                    text "Sft+Z"
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.derefSimulator(helper).redo):
                text "Redo"
                if not helper.mobile:
                  span(style = counterStyle):
                    text "Sft+Y"
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).reset
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-fast")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "Z"
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).backward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-step")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "X"
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).forward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-forward-step")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "C"
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(
                class = insertBtnCls,
                onclick = () => self.derefSimulator(helper).toggleInsert,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-indent")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "I"
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).shiftFieldUp,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-up")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "Sft+W"
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).flipFieldHorizontal,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-right-left")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "F"
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).shiftFieldLeft,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-left")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "Sft+A"
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).shiftFieldDown,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-down")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "Sft+S"
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).shiftFieldRight,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-right")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "Sft+D"
        of ViewerEdit, Replay:
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).reset
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-fast")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "Z"
            tdiv(class = "control", style = fieldStyle):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).backward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-step")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "X"
            tdiv(class = "control", style = fieldStyle):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).forward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-forward-step")
                  if not helper.mobile:
                    span(style = counterStyle):
                      text "C"
        of PlayModes:
          if helper.mobile:
            tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
              tdiv(class = "control"):
                button(
                  class = "button", onclick = () => self.derefSimulator(helper).reset
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-backward-fast")
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).forward(skip = true),
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-angles-right")
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).forward(replay = true),
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-forward-step")
          else:
            tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
              tdiv(class = "control"):
                button(
                  class = "button", onclick = () => self.derefSimulator(helper).reset
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-backward-fast")
                    span(style = counterStyle):
                      text "Z"
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).forward(skip = true),
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-angles-right")
                    span(style = counterStyle):
                      text "Space"
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).forward(replay = true),
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-forward-step")
                    span(style = counterStyle):
                      text "C"
            tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).rotatePlacementLeft,
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-rotate-left")
                    span(style = counterStyle):
                      text "J"
              tdiv(class = "control"):
                button(
                  class = "button", onclick = () => self.derefSimulator(helper).backward
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-up")
                    span(style = counterStyle):
                      text "W"
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).rotatePlacementRight,
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-rotate-right")
                    span(style = counterStyle):
                      text "K"
            tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).movePlacementLeft,
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-left")
                    span(style = counterStyle):
                      text "A"
              tdiv(class = "control"):
                button(
                  class = "button", onclick = () => self.derefSimulator(helper).forward
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-down")
                    span(style = counterStyle):
                      text "S"
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).movePlacementRight,
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-right")
                    span(style = counterStyle):
                      text "D"

  proc toBottomCtrlVNode*[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper
  ): VNode {.inline.} =
    ## Returns the controller node replaced bottom of the window.
    buildHtml tdiv(class = "card", style = translucentStyle):
      tdiv(class = "card-content p-1"):
        case self.derefSimulator(helper).mode
        of PlayModes:
          tdiv(class = "field is-grouped is-grouped-centered"):
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).rotatePlacementLeft,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-rotate-left")
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).backward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-up")
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).rotatePlacementRight,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-rotate-right")
          tdiv(class = "field is-grouped is-grouped-centered"):
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).movePlacementLeft,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-left")
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).forward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-down")
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).movePlacementRight,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-right")
        of ViewerEdit:
          tdiv(class = "field is-grouped is-grouped-is-centered mb-0"):
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).backward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-step")
          tdiv(class = "field is-grouped is-grouped-is-centered"):
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).forward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-forward-step")
        of Replay:
          tdiv(class = "field is-grouped is-grouped-centered"):
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).reset
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-fast")
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).backward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-step")
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).forward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-forward-step")
        of EditorEdit:
          discard
