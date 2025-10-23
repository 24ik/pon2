## This module implements settings views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../[app]

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karax, karaxdsl, vdom]
  import ../../core/[rule] # NOTE: import `core` causes warning due to Nim's bug
  import ../../private/[gui]

type SettingsView* = object ## View of the settings.
  simulator: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type SettingsView, simulator: ref Simulator): T {.inline.} =
  T(simulator: simulator)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const
    BtnCls = "button".cstring
    SelectBtnCls = "button is-primary is-selected".cstring

  proc toVNode*(self: SettingsView): VNode {.inline.} =
    ## Returns the select node.
    let playBtnCls, editBtnCls: cstring
    if self.simulator[].mode in PlayModes:
      playBtnCls = SelectBtnCls
      editBtnCls = BtnCls
    else:
      playBtnCls = BtnCls
      editBtnCls = SelectBtnCls

    let playMode, editMode: SimulatorMode
    if self.simulator[].mode in ViewerModes:
      playMode = ViewerPlay
      editMode = ViewerEdit
    else:
      playMode = EditorPlay
      editMode = EditorEdit

    let mobile = isMobile()

    buildHtml tdiv:
      tdiv(class = "field has-addons"):
        tdiv(class = "control"):
          button(class = playBtnCls, onclick = () => (self.simulator[].mode = playMode)):
            span(class = "icon"):
              italic(class = "fa-solid fa-gamepad")
              if not mobile and self.simulator[].mode notin PlayModes:
                span(style = counterStyle):
                  text "M"
        tdiv(class = "control"):
          button(class = editBtnCls, onclick = () => (self.simulator[].mode = editMode)):
            span(class = "icon"):
              italic(class = "fa-solid fa-pen-to-square")
              if not mobile and self.simulator[].mode notin EditModes:
                span(style = counterStyle):
                  text "M"
      if self.simulator[].mode == EditorEdit:
        let tsuBtnCls, waterBtnCls: cstring
        case self.simulator[].rule
        of Tsu:
          tsuBtnCls = SelectBtnCls
          waterBtnCls = BtnCls
        else:
          tsuBtnCls = BtnCls
          waterBtnCls = SelectBtnCls

        tdiv(class = "field has-addons"):
          tdiv(class = "control"):
            button(class = tsuBtnCls, onclick = () => (self.simulator[].rule = Tsu)):
              span(class = "icon"):
                italic(class = "fa-solid fa-2")
                if not mobile and self.simulator[].rule != Tsu:
                  span(style = counterStyle):
                    text "R"
          tdiv(class = "control"):
            button(class = waterBtnCls, onclick = () => (self.simulator[].rule = Water)):
              span(class = "icon"):
                italic(class = "fa-solid fa-droplet")
                if not mobile and self.simulator[].rule != Water:
                  span(style = counterStyle):
                    text "R"
