## This module implements marathon views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[jsffi, strformat]
  import karax/[karax, karaxdsl, vdom]
  import ./[ctrl, search]
  import ../[helper, simulator]
  import ../../[app]
  import ../../private/[gui]

  proc toMarathonVNode*(
      self: ref Marathon, helper: VNodeHelper
  ): VNode {.inline, noinit.} =
    ## Returns the marathon node.
    buildHtml tdiv:
      tdiv(class = "block"):
        self.toMarathonSearchVNode helper
      tdiv(class = "block"):
        self.toMarathonCtrlVNode helper
      tdiv(class = "block"):
        self.toSimulatorVNode helper
