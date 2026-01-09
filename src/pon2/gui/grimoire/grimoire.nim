## This module implements grimoire views.
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
  import ./[exchange, match, navbar, table]
  import ../[helper, simulator]
  import ../../[app]
  import ../../private/[gui]

  export vdom

  proc toGrimoireVNode*(self: ref Grimoire, helper: VNodeHelper): VNode =
    ## Returns the grimoire node.
    buildHtml tdiv:
      self.toGrimoireNavbarVNode helper
      tdiv(class = "block"):
        tdiv(class = "columns"):
          tdiv(class = "column is-narrow"):
            self.toGrimoireMatchVNode helper
          tdiv(class = "column is-narrow"):
            self.toGrimoireMatchResultVNode helper
      tdiv(class = "block"):
        self.toSimulatorVNode helper
      tdiv(class = "block"):
        self.toGrimoireExchangeVNode helper
