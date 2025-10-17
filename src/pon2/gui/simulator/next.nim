## This module implements nexts views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../[app]

when defined(js) or defined(nimsuggest):
  import karax/[karaxdsl, vdom]
  import ../../[core]
  import ../../private/gui/[simulator]

type NextsView* = object ## View of the next steps.
  simulator: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type NextsView, simulator: ref Simulator): T {.inline.} =
  T(simulator: simulator)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  func nextCell(self: NextsView, dblNext: bool, pivot: bool): Cell {.inline.} =
    ## Returns the cell in the next or double-next step.
    let stepIdx = self.simulator[].operatingIdx.succ 1 + dblNext.int

    self.simulator[].nazoPuyoWrap.runIt:
      if stepIdx < it.steps.len:
        let step = it.steps[stepIdx]
        case step.kind
        of PairPlacement:
          if pivot: step.pair.pivot else: step.pair.rotor
        of StepKind.Garbages:
          if step.dropHard: Hard else: Garbage
      else:
        Cell.None

  proc toVNode*(self: NextsView): VNode {.inline.} =
    ## Returns the next node.
    buildHtml table:
      tbody:
        # indent
        for _ in 1 .. 4:
          tr:
            td:
              figure(class = "image is-24x24"):
                img(src = Cell.None.cellImgSrc)

        # next
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = self.nextCell(dblNext = false, pivot = false).cellImgSrc)
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = self.nextCell(dblNext = false, pivot = true).cellImgSrc)

        # separator
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = Cell.None.cellImgSrc)

        # double next
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = self.nextCell(dblNext = true, pivot = false).cellImgSrc)
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = self.nextCell(dblNext = true, pivot = true).cellImgSrc)
