## This module implements IDE pagination views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../[app]

when defined(js) or defined(nimsuggest):
  import std/[strformat, sugar]
  import karax/[karax, karaxdsl, vdom]

type IdePaginationView* = object ## View of the IDE pagination.
  ide: ref Ide

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type IdePaginationView, ide: ref Ide): T {.inline.} =
  T(ide: ide)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  proc toVNode*(self: IDEPaginationView): VNode {.inline.} =
    ## Returns the IDE pagination node.
    let replayNum =
      if self.ide[].replayStepsCnt == 0:
        0
      else:
        self.ide[].replayStepsIdx.succ

    buildHtml nav(class = "pagination"):
      button(class = "button pagination-link", onclick = () => self.ide[].prevReplay):
        span(class = "icon"):
          italic(class = "fa-solid fa-backward-step")
      button(class = "button pagination-link is-static"):
        text "{replayNum} / {self.ide[].replayStepsCnt}".fmt
      button(class = "button pagination-link", onclick = () => self.ide[].nextReplay):
        span(class = "icon"):
          italic(class = "fa-solid fa-forward-step")
