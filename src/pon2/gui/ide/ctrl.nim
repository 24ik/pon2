## This module implements IDE controller views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../[app]

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karax, karaxdsl, vdom]
  import ./[setting]
  import ../../private/[gui]

type IdeCtrlView* = object ## View of the IDE controller.
  ide: ref Ide

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type IdeCtrlView, ide: ref Ide): T {.inline.} =
  T(ide: ide)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  proc runPermute(ide: ref Ide, settingId: cstring) {.inline.} =
    ## Permutes the nazo puyo.
    let settings = settingId.getIdeSetting
    ide[].permute settings.fixIndices, settings.allowDblNotLast, settings.allowDblLast

  proc toVNode*(self: IdeCtrlView, settingId: cstring): VNode {.inline.} =
    ## Returns the IDE controller node.
    let mobile = isMobile()

    buildHtml tdiv(class = "field is-grouped"):
      tdiv(class = "control"):
        button(
          class = "button",
          disabled = self.ide[].working,
          onclick = () => self.ide[].solve,
        ):
          text "解探索"
          if not mobile:
            span(style = counterStyle):
              text "Enter"
      tdiv(class = "control"):
        button(
          class = "button",
          disabled = self.ide[].working,
          onclick = () => self.ide.runPermute settingId,
        ):
          text "ツモ並べ替え"
      if not mobile:
        tdiv(class = "control"):
          button(
            class =
              (if self.ide[].focusReplay: "button is-primary" else: "button").cstring,
            onclick = () => self.ide[].toggleFocus,
          ):
            text "解答を操作"
            span(style = counterStyle):
              text "Sft+Tab"
