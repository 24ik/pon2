## This module implements studio controller views.
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
  import karax/[karax, karaxdsl, vdom]
  import ./[setting]
  import ../../[app]
  import ../../private/[gui]

  proc runPermute(self: ref Studio, helper: VNodeHelper) {.inline.} =
    ## Permutes the nazo puyo.
    let settings = helper.getStudioSetting
    self[].permute settings.fixIndices, settings.allowDblNotLast, settings.allowDblLast

  proc toStudioCtrlVNode*(self: ref Studio, helper: VNodeHelper): VNode {.inline.} =
    ## Returns the studio controller node.
    buildHtml tdiv(class = "field is-grouped"):
      tdiv(class = "control"):
        button(
          class = "button", disabled = self[].working, onclick = () => self[].solve
        ):
          text "解探索"
          if not helper.mobile:
            span(style = counterStyle):
              text "Enter"
      tdiv(class = "control"):
        button(
          class = "button",
          disabled = self[].working,
          onclick = () => self.runPermute helper,
        ):
          text "ツモ並べ替え"
      if not helper.mobile:
        tdiv(class = "control"):
          button(
            class = (if self[].focusReplay: "button is-primary" else: "button").cstring,
            onclick = () => self[].toggleFocus,
          ):
            text "解答を操作"
            span(style = counterStyle):
              text "Sft+Tab"
