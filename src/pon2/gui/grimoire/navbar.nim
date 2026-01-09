## This module implements grimoire navigation bar views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[strformat]
  import karax/[karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[gui, strutils]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  proc toGrimoireNavbarVNode*(self: ref Grimoire, helper: VNodeHelper): VNode =
    ## Returns the grimoire navigation bar node.
    buildHtml nav(class = "navbar is-fixed-top is-light has-shadow"):
      tdiv(class = "navbar-brand"):
        tdiv(class = "navbar-item"):
          text "正解数：{helper.grimoireOpt.unsafeValue.solvedEntryIndices.card}/{self[].len}問".fmt.kstring
