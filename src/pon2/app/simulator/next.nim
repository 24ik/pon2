## This module implements next view.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import karax/[karaxdsl, vdom]
  import ../[nazopuyowrap, simulator]
  import ../../[core]
  import ../../private/app/simulator/[common]

type NextView* = object ## View of the next step.
  simulator: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type NextView, simulator: ref Simulator): T {.inline.} =
  T(simulator: simulator)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

# TODO: better impl (indent, separator, Garbages)
when defined(js) or defined(nimsuggest):
  func nextCell(step: Step, pivot: bool): Cell {.inline.} =
    ## Returns the cell in the step.
    case step.kind
    of PairPlacement:
      if pivot: step.pair.pivot else: step.pair.rotor
    of StepKind.Garbages:
      if step.dropHard: Hard else: Garbage

  func nextCell(self: NextView, pivot: bool): Cell {.inline.} =
    ## Returns the cell in the next step.
    self.simulator[].nazoPuyoWrap.runIt:
      if self.simulator[].operatingIdx >= it.steps.len:
        return Cell.None

      it.steps[self.simulator[].operatingIdx].nextCell pivot

  func doubleNextCell(self: NextView, pivot: bool): Cell {.inline.} =
    ## Returns the cell in the double next step.
    self.simulator[].nazoPuyoWrap.runIt:
      if self.simulator[].operatingIdx.succ >= it.steps.len:
        return Cell.None

      it.steps[self.simulator[].operatingIdx.succ].nextCell pivot

  proc toVNode*(self: NextView): VNode {.inline.} =
    ## Returns the next node.
    buildHtml(table):
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
              img(src = self.nextCell(false).cellImgSrc)
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = self.nextCell(true).cellImgSrc)

        # separator
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = Cell.None.cellImgSrc)

        # double next
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = self.doubleNextCell(false).cellImgSrc)
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = self.doubleNextCell(true).cellImgSrc)
