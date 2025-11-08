## This module implements studio views.
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
  import ./[ctrl, pagination, setting]
  import ../[helper, simulator]
  import ../../[app]
  import ../../private/[gui]

  proc toStudioVNode*(
      self: ref Studio, helper, replayHelper: VNodeHelper
  ): VNode {.inline.} =
    ## Returns the studio node.
    buildHtml tdiv(class = "columns"):
      tdiv(class = "column is-narrow"):
        self.toSimulatorVNode helper
      if self[].simulator.mode in EditorModes and
          self[].simulator.nazoPuyoWrap.optGoal.isOk:
        tdiv(class = "column is-narrow"):
          tdiv(class = "block"):
            self.toStudioCtrlVNode helper
          tdiv(class = "block"):
            self.toStudioSettingsVNode helper
          tdiv(class = "block"):
            self.toStudioPaginationVNode helper
          if self[].replayStepsCnt > 0:
            tdiv(class = "block"):
              self.toSimulatorVNode replayHelper
