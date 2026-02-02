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
  import ../[helper]
  import ../../[app]
  import ../../private/[gui]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  proc toSideCtrlVNode*[S: Simulator or Studio or Marathon or Grimoire](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the controller node replaced next the field.
    let
      insertBtnCls = (
        if self.derefSimulator(helper).editData.insert: "button is-primary"
        else: "button"
      ).kstring
      fieldStyle =
        if helper.mobile:
          style(StyleAttr.columnGap, "0.5em")
        else:
          style()
      mode = self.derefSimulator(helper).mode
      keyBinds = SimulatorKeyBindsArray[self.derefSimulator(helper).keyBindPattern]

    buildHtml tdiv(class = "card", style = translucentStyle):
      tdiv(class = "card-content p-1"):
        case mode
        of EditEditor:
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.derefSimulator(helper).undo):
                text "Undo"
                if not helper.mobile:
                  keyBinds.editUndo.toKeyBindDescVNode
            tdiv(class = "control"):
              button(class = "button", onclick = () => self.derefSimulator(helper).redo):
                text "Redo"
                if not helper.mobile:
                  keyBinds.editRedo.toKeyBindDescVNode
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).reset
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-fast")
                  if not helper.mobile:
                    keyBinds.editReset.toKeyBindDescVNode
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).backward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-step")
                  if not helper.mobile:
                    keyBinds.editBackward.toKeyBindDescVNode
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).forward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-forward-step")
                  if not helper.mobile:
                    keyBinds.editForward.toKeyBindDescVNode
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(
                class = insertBtnCls,
                onclick = () => self.derefSimulator(helper).toggleInsert,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-indent")
                  if not helper.mobile:
                    keyBinds.editInsertToggle.toKeyBindDescVNode
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).shiftFieldUp,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-up")
                  if not helper.mobile:
                    keyBinds.editFieldShiftUp.toKeyBindDescVNode
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).flipFieldHorizontal,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-right-arrow-left")
                  if not helper.mobile:
                    keyBinds.editFieldFlip.toKeyBindDescVNode
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).shiftFieldLeft,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-left")
                  if not helper.mobile:
                    keyBinds.editFieldShiftLeft.toKeyBindDescVNode
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).shiftFieldDown,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-down")
                  if not helper.mobile:
                    keyBinds.editFieldShiftDown.toKeyBindDescVNode
            tdiv(class = "control"):
              button(
                class = "button",
                onclick = () => self.derefSimulator(helper).shiftFieldRight,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-angles-right")
                  if not helper.mobile:
                    keyBinds.editFieldShiftRight.toKeyBindDescVNode
        of EditViewer, Replay:
          tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
            tdiv(class = "control"):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).reset
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-fast")
                  if not helper.mobile:
                    (
                      if mode == EditViewer: keyBinds.editReset
                      else: keyBinds.replayReset
                    ).toKeyBindDescVNode
            tdiv(class = "control", style = fieldStyle):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).backward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-step")
                  if not helper.mobile:
                    (
                      if mode == EditViewer: keyBinds.editBackward
                      else: keyBinds.replayBackward
                    ).toKeyBindDescVNode
            tdiv(class = "control", style = fieldStyle):
              button(
                class = "button", onclick = () => self.derefSimulator(helper).forward
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-forward-step")
                  if not helper.mobile:
                    (
                      if mode == EditViewer: keyBinds.editForward
                      else: keyBinds.replayForward
                    ).toKeyBindDescVNode
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
                    keyBinds.playReset.toKeyBindDescVNode
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).forward(skip = true),
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-angles-right")
                    keyBinds.playForwardSkip.toKeyBindDescVNode
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).forward(replay = true),
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-forward-step")
                    keyBinds.playForwardReplay.toKeyBindDescVNode
            tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).rotatePlacementLeft,
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-rotate-left")
                    keyBinds.playRotateLeft.toKeyBindDescVNode
              tdiv(class = "control"):
                button(
                  class = "button", onclick = () => self.derefSimulator(helper).backward
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-backward-step")
                    keyBinds.playBackward.toKeyBindDescVNode
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).rotatePlacementRight,
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-rotate-right")
                    keyBinds.playRotateRight.toKeyBindDescVNode
            tdiv(class = "field is-grouped is-grouped-centered", style = fieldStyle):
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).movePlacementLeft,
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-left")
                    keyBinds.playMoveLeft.toKeyBindDescVNode
              tdiv(class = "control"):
                button(
                  class = "button", onclick = () => self.derefSimulator(helper).forward
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-down")
                    keyBinds.playForward.toKeyBindDescVNode
              tdiv(class = "control"):
                button(
                  class = "button",
                  onclick = () => self.derefSimulator(helper).movePlacementRight,
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-arrow-right")
                    keyBinds.playMoveRight.toKeyBindDescVNode

  proc toBottomCtrlVNode*[S: Simulator or Studio or Marathon or Grimoire](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the controller node replaced bottom of the window.
    buildHtml tdiv(class = "card", style = translucentStyle):
      tdiv(class = "card-content p-1"):
        case self.derefSimulator(helper).mode
        of PlayModes:
          tdiv(class = "field is-grouped is-grouped-centered"):
            tdiv(class = "control"):
              button(
                class = "button is-large",
                onclick = () => self.derefSimulator(helper).rotatePlacementLeft,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-rotate-left")
            tdiv(class = "control"):
              button(
                class = "button is-large",
                onclick = () => self.derefSimulator(helper).backward,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-step")
            tdiv(class = "control"):
              button(
                class = "button is-large",
                onclick = () => self.derefSimulator(helper).rotatePlacementRight,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-rotate-right")
          tdiv(class = "field is-grouped is-grouped-centered"):
            tdiv(class = "control"):
              button(
                class = "button is-large",
                onclick = () => self.derefSimulator(helper).movePlacementLeft,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-left")
            tdiv(class = "control"):
              button(
                class = "button is-large",
                onclick = () => self.derefSimulator(helper).forward,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-down")
            tdiv(class = "control"):
              button(
                class = "button is-large",
                onclick = () => self.derefSimulator(helper).movePlacementRight,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-arrow-right")
        of EditViewer:
          tdiv(class = "field is-grouped is-grouped-centered mb-0"):
            tdiv(class = "control"):
              button(
                class = "button is-large px-4 py-2",
                onclick = () => self.derefSimulator(helper).backward,
              ):
                span(class = "icon is-medium"):
                  italic(class = "fa-solid fa-backward-step")
          tdiv(class = "field is-grouped is-grouped-centered"):
            tdiv(class = "control"):
              button(
                class = "button is-large px-4 py-2",
                onclick = () => self.derefSimulator(helper).forward,
              ):
                span(class = "icon is-medium"):
                  italic(class = "fa-solid fa-forward-step")
        of Replay:
          tdiv(class = "field is-grouped is-grouped-centered"):
            tdiv(class = "control"):
              button(
                class = "button is-large",
                onclick = () => self.derefSimulator(helper).reset,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-fast")
            tdiv(class = "control"):
              button(
                class = "button is-large",
                onclick = () => self.derefSimulator(helper).backward,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-backward-step")
            tdiv(class = "control"):
              button(
                class = "button is-large",
                onclick = () => self.derefSimulator(helper).forward,
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-forward-step")
        of EditEditor:
          discard
