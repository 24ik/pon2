## This module implements operating views.
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

  proc operatingCell[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, idx: int, col: Col
  ): Cell {.inline.} =
    ## Returns the cell in the operating area.
    if self.derefSimulator(helper).state != Stable:
      return Cell.None
    if self.derefSimulator(helper).mode notin PlayModes:
      return Cell.None

    let
      nazoWrap = self.derefSimulator(helper).nazoPuyoWrap
      steps = nazoWrap.unwrapNazoPuyo:
        it.steps
    if self.derefSimulator(helper).operatingIdx >= steps.len:
      return Cell.None

    let step = steps[self.derefSimulator(helper).operatingIdx]
    case step.kind
    of PairPlacement:
      # pivot
      if idx == 1 and col == self.derefSimulator(helper).operatingPlacement.pivotCol:
        step.pair.pivot
      # rotor
      elif col == self.derefSimulator(helper).operatingPlacement.rotorCol:
        if idx == 1:
          step.pair.rotor
        elif idx == 0 and self.derefSimulator(helper).operatingPlacement.rotorDir == Up:
          step.pair.rotor
        elif idx == 2 and self.derefSimulator(helper).operatingPlacement.rotorDir == Down:
          step.pair.rotor
        else:
          Cell.None
      else:
        Cell.None
    of StepKind.Garbages:
      if idx == 2 and step.cnts[col] > 0:
        (if step.dropHard: Hard else: Garbage)
      else:
        Cell.None

  proc toOperatingVNode*[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper
  ): VNode {.inline.} =
    ## Returns the operating node.
    buildHtml table:
      tbody:
        for idx in 0 ..< 3:
          tr:
            for col in Col:
              td:
                figure(class = "image is-24x24"):
                  img(src = self.operatingCell(helper, idx, col).cellImgSrc)
