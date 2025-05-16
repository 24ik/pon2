## This module implements select views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karax, karaxdsl, vdom]
  import ../[simulator]
  import ../../core/[rule] # NOTE: import `core` causes warning due to Nim's bug

type SelectView* = object ## View of the selection.
  simulator: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type SelectView, simulator: ref Simulator): T {.inline.} =
  T(simulator: simulator)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const SelectBtnCls = "button is-selected is-primary".cstring

  proc toVNode*(self: SelectView): VNode {.inline.} =
    ## Returns the select node.
    let playBtnCls, editBtnCls: cstring
    if self.simulator[].mode in PlayModes:
      playBtnCls = SelectBtnCls
      editBtnCls = "button"
    else:
      playBtnCls = "button"
      editBtnCls = SelectBtnCls

    let playMode, editMode: SimulatorMode
    if self.simulator[].mode in ViewerModes:
      playMode = ViewerPlay
      editMode = ViewerEdit
    else:
      playMode = EditorPlay
      editMode = EditorEdit

    let tsuBtnCls, waterBtnCls: cstring
    case self.simulator[].rule
    of Tsu:
      tsuBtnCls = SelectBtnCls
      waterBtnCls = "button"
    else:
      tsuBtnCls = "button"
      waterBtnCls = SelectBtnCls

    buildHtml tdiv:
      tdiv(class = "buttons has-addons mb-1"):
        button(class = playBtnCls, onclick = () => (self.simulator[].mode = playMode)):
          span(class = "icon"):
            italic(class = "fa-solid fa-gamepad")
        button(class = editBtnCls, onclick = () => (self.simulator[].mode = editMode)):
          span(class = "icon"):
            italic(class = "fa-solid fa-pen-to-square")
      if self.simulator[].mode == EditorEdit:
        tdiv(class = "buttons has-addons"):
          button(class = tsuBtnCls, onclick = () => (self.simulator[].rule = Tsu)):
            span(class = "icon"):
              italic(class = "fa-solid fa-2")
          button(class = waterBtnCls, onclick = () => (self.simulator[].rule = Water)):
            span(class = "icon"):
              italic(class = "fa-solid fa-water")
