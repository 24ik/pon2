## This module implements marathon controller views.
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
  import ../[helper]
  import ../../[app]
  import ../../private/[gui]

  export vdom

  proc toMarathonCtrlVNode*(self: ref Marathon, helper: VNodeHelper): VNode =
    ## Returns the marathon controller node.
    buildHtml tdiv:
      p:
        text "ランダムにツモ読込"
      tdiv(class = "field is-grouped"):
        tdiv(class = "control"):
          button(
            class = "button",
            onclick = () => self[].selectRandomQuery(fromMatched = false),
            disabled = not self[].isReady,
          ):
            text "全ツモ"
            if not helper.mobile:
              span(style = counterStyle):
                text "Sft+Enter"

        tdiv(class = "control"):
          button(
            class = "button",
            onclick = () => self[].selectRandomQuery,
            disabled = self[].matchQueryCount == 0,
          ):
            text "指定ツモ"
            if not helper.mobile:
              span(style = counterStyle):
                text "Enter"
