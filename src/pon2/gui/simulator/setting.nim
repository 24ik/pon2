## This module implements settings views.
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
  import karax/[karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[gui]

  const
    BtnCls = "button".cstring
    SelectBtnCls = "button is-primary is-selected".cstring

  proc toSettingsVNode*[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper
  ): VNode {.inline.} =
    ## Returns the select node.
    let playBtnCls, editBtnCls: cstring
    if self.derefSimulator(helper).mode in PlayModes:
      playBtnCls = SelectBtnCls
      editBtnCls = BtnCls
    else:
      playBtnCls = BtnCls
      editBtnCls = SelectBtnCls

    let playMode, editMode: SimulatorMode
    if self.derefSimulator(helper).mode in ViewerModes:
      playMode = ViewerPlay
      editMode = ViewerEdit
    else:
      playMode = EditorPlay
      editMode = EditorEdit

    buildHtml tdiv:
      tdiv(class = "field has-addons"):
        tdiv(class = "control"):
          button(
            class = playBtnCls,
            onclick = () => (self.derefSimulator(helper).mode = playMode),
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-gamepad")
              if not helper.mobile and self.derefSimulator(helper).mode notin PlayModes:
                span(style = counterStyle):
                  text "T"
        tdiv(class = "control"):
          button(
            class = editBtnCls,
            onclick = () => (self.derefSimulator(helper).mode = editMode),
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-pen-to-square")
              if not helper.mobile and self.derefSimulator(helper).mode notin EditModes:
                span(style = counterStyle):
                  text "T"
      if self.derefSimulator(helper).mode == EditorEdit:
        let tsuBtnCls, waterBtnCls: cstring
        case self.derefSimulator(helper).rule
        of Tsu:
          tsuBtnCls = SelectBtnCls
          waterBtnCls = BtnCls
        else:
          tsuBtnCls = BtnCls
          waterBtnCls = SelectBtnCls

        tdiv(class = "field has-addons"):
          tdiv(class = "control"):
            button(
              class = tsuBtnCls,
              onclick = () => (self.derefSimulator(helper).rule = Tsu),
            ):
              span(class = "icon"):
                italic(class = "fa-solid fa-2")
                if not helper.mobile and self.derefSimulator(helper).rule != Tsu:
                  span(style = counterStyle):
                    text "R"
          tdiv(class = "control"):
            button(
              class = waterBtnCls,
              onclick = () => (self.derefSimulator(helper).rule = Water),
            ):
              span(class = "icon"):
                italic(class = "fa-solid fa-droplet")
                if not helper.mobile and self.derefSimulator(helper).rule != Water:
                  span(style = counterStyle):
                    text "R"
