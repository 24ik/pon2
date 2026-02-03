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
  import std/[sequtils, sugar]
  import karax/[karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[gui, utils]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  const
    BtnClass = "button".kstring
    SelectBtnClass = "button is-primary is-selected".kstring

  func initBtnHandler[S: Simulator or Studio or Marathon or Grimoire](
      self: ref S, helper: VNodeHelper, rule: Rule
  ): () -> void =
    ## Returns the handler for clicking buttons.
    () => self.derefSimulator(helper).setRule rule

  proc toSettingsVNode*[S: Simulator or Studio or Marathon or Grimoire](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the select node.
    let playBtnClass, editBtnClass: kstring
    if self.derefSimulator(helper).mode in PlayModes:
      playBtnClass = SelectBtnClass
      editBtnClass = BtnClass
    else:
      playBtnClass = BtnClass
      editBtnClass = SelectBtnClass

    let playMode, editMode: SimulatorMode
    if self.derefSimulator(helper).mode in ViewerModes:
      playMode = PlayViewer
      editMode = EditViewer
    else:
      playMode = PlayEditor
      editMode = EditEditor

    let keyBinds = SimulatorKeyBindsArray[self.derefSimulator(helper).keyBindPattern]

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
                keyBinds.modeToggle.toKeyBindDescVNode
        tdiv(class = "control"):
          button(
            class = editBtnClass,
            onclick = () => (self.derefSimulator(helper).mode = editMode),
          ):
            span(class = "icon"):
              italic(class = "fa-solid fa-pen-to-square")
              if not helper.mobile and self.derefSimulator(helper).mode notin EditModes:
                keyBinds.modeToggle.toKeyBindDescVNode
      if self.derefSimulator(helper).mode == EditEditor:
        let nowRule = self.derefSimulator(helper).rule

        tdiv(class = "field has-addons"):
          for rule in Rule:
            let
              selected = rule == nowRule
              btnClass = if selected: SelectBtnClass else: BtnClass
              steps = self.derefSimulator(helper).nazoPuyo.puyoPuyo.steps
              (italicClass, disabled) =
                case rule
                of Rule.Tsu:
                  ("fa-solid fa-2".kstring, steps.anyIt it.kind == FieldRotate)
                of Spinner:
                  (
                    "fa-solid fa-arrows-rotate".kstring,
                    steps.anyIt (it.kind == FieldRotate and it.cross),
                  )
                of CrossSpinner:
                  (
                    "DUMMY".kstring,
                    steps.anyIt (it.kind == FieldRotate and not it.cross),
                  )
                of Rule.Water:
                  ("fa-solid fa-droplet".kstring, steps.anyIt it.kind == FieldRotate)

            tdiv(class = "control"):
              button(
                class = btnClass,
                disabled = disabled and not selected,
                onclick = self.initBtnHandler(helper, rule),
              ):
                span(class = "icon"):
                  case rule
                  of CrossSpinner:
                    span(class = "fa-stack", style = style(StyleAttr.fontSize, "0.5em")):
                      italic(class = "fa-solid fa-arrows-rotate fa-stack-2x")
                      italic(class = "fa-solid fa-c fa-stack-1x")
                  else:
                    italic(class = italicClass)
                  if not helper.mobile:
                    if rule == nowRule.rotateSucc:
                      keyBinds.editRuleNext.toKeyBindDescVNode
                    elif rule == nowRule.rotatePred:
                      keyBinds.editRulePrev.toKeyBindDescVNode
