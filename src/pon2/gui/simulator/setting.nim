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

  export vdom

  const
    BtnClass = "button".cstring
    SelectBtnClass = "button is-primary is-selected".cstring

  proc toSettingsVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the select node.
    let playBtnClass, editBtnClass: cstring
    if self.derefSimulator(helper).mode in PlayModes:
      playBtnClass = SelectBtnClass
      editBtnClass = BtnClass
    else:
      playBtnClass = BtnClass
      editBtnClass = SelectBtnClass

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
            class = playBtnClass,
            onclick = () => (self.derefSimulator(helper).mode = playMode),
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-gamepad")
              if not helper.mobile and self.derefSimulator(helper).mode notin PlayModes:
                span(style = counterStyle):
                  text "T"
        tdiv(class = "control"):
          button(
            class = editBtnClass,
            onclick = () => (self.derefSimulator(helper).mode = editMode),
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-pen-to-square")
              if not helper.mobile and self.derefSimulator(helper).mode notin EditModes:
                span(style = counterStyle):
                  text "T"
      if self.derefSimulator(helper).mode == EditorEdit:
        let tsuBtnClass, waterBtnClass: cstring
        case self.derefSimulator(helper).rule
        of Tsu:
          tsuBtnClass = SelectBtnClass
          waterBtnClass = BtnClass
        else:
          tsuBtnClass = BtnClass
          waterBtnClass = SelectBtnClass

        tdiv(class = "field has-addons"):
          tdiv(class = "control"):
            button(
              class = tsuBtnClass,
              onclick = () => (self.derefSimulator(helper).rule = Tsu),
            ):
              span(class = "icon"):
                italic(class = "fa-solid fa-2")
                if not helper.mobile and self.derefSimulator(helper).rule != Tsu:
                  span(style = counterStyle):
                    text "R"
          tdiv(class = "control"):
            button(
              class = waterBtnClass,
              onclick = () => (self.derefSimulator(helper).rule = Water),
            ):
              span(class = "icon"):
                italic(class = "fa-solid fa-droplet")
                if not helper.mobile and self.derefSimulator(helper).rule != Water:
                  span(style = counterStyle):
                    text "R"
