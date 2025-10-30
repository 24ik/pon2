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
  import ../[helper]
  import ../../[app]
  import ../../private/[gui, results2]

  proc toNextCellVNode[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, dblNext: bool, pivot: bool
  ): VNode {.inline.} =
    ## Returns the node of the cell in the next or double-next step.
    let
      stepIdx = self.derefSimulator(helper).operatingIdx.succ 1 + dblNext.int
      nazoWrap = self.derefSimulator(helper).nazoPuyoWrap

    var cross = false
    let cellOpt = nazoWrap.unwrapNazoPuyo:
      if stepIdx < it.steps.len:
        let step = it.steps[stepIdx]
        case step.kind
        of PairPlacement:
          Opt[Cell].ok if pivot: step.pair.pivot else: step.pair.rotor
        of StepKind.Garbages:
          Opt[Cell].ok if step.dropHard: Hard else: Garbage
        of Rotate:
          cross = step.cross

          if pivot:
            Opt[Cell].err
          else:
            Opt[Cell].ok Cell.None
      else:
        Opt[Cell].ok Cell.None

    buildHtml figure(class = "image is-24x24"):
      if cellOpt.isOk:
        img(src = cellOpt.unsafeValue.cellImgSrc)
      else:
        span(class = "icon"):
          italic(
            class = (
              if cross: "fa-solid fa-arrows-rotate" else: "fa-solid fa-rotate-right"
            ).cstring
          )

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
            self.toNextCellVNode(helper, dblNext = false, pivot = false)
        tr:
          td:
            self.toNextCellVNode(helper, dblNext = false, pivot = true)

        # separator
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = Cell.None.cellImgSrc)

        # double next
        tr:
          td:
            self.toNextCellVNode(helper, dblNext = true, pivot = false)
        tr:
          td:
            self.toNextCellVNode(helper, dblNext = true, pivot = true)
