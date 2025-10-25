## This module implements nexts views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import karax/[karaxdsl, vdom]
  import ../../[app]
  import ../../private/[gui]

  proc nextCell[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, dblNext: bool, pivot: bool
  ): Cell {.inline.} =
    ## Returns the cell in the next or double-next step.
    let
      stepIdx = self.derefSimulator(helper).operatingIdx.succ 1 + dblNext.int
      nazoWrap = self.derefSimulator(helper).nazoPuyoWrap

    nazoWrap.unwrapNazoPuyo:
      if stepIdx < it.steps.len:
        let step = it.steps[stepIdx]
        case step.kind
        of PairPlacement:
          if pivot: step.pair.pivot else: step.pair.rotor
        of StepKind.Garbages:
          if step.dropHard: Hard else: Garbage
      else:
        Cell.None

  proc toNextVNode*[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper
  ): VNode {.inline.} =
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
              img(
                src = self.nextCell(helper, dblNext = false, pivot = false).cellImgSrc
              )
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = self.nextCell(helper, dblNext = false, pivot = true).cellImgSrc)

        # separator
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = Cell.None.cellImgSrc)

        # double next
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = self.nextCell(helper, dblNext = true, pivot = false).cellImgSrc)
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = self.nextCell(helper, dblNext = true, pivot = true).cellImgSrc)
