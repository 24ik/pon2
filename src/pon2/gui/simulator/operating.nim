## This module implements operating views.
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

type OperatingView* = object ## View of the operating.
  simulator: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type OperatingView, simulator: ref Simulator): T {.inline.} =
  T(simulator: simulator)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  func operatingCell(self: OperatingView, idx: int, col: Col): Cell {.inline.} =
    ## Returns the cell in the operating area.
    if self.simulator[].state != Stable:
      return Cell.None
    if self.simulator[].mode notin PlayModes:
      return Cell.None

    self.simulator[].nazoPuyoWrap.runIt:
      if self.simulator[].operatingIdx >= it.steps.len:
        return Cell.None

      let step = it.steps[self.simulator[].operatingIdx]
      case step.kind
      of PairPlacement:
        # pivot
        if idx == 1 and col == self.simulator[].operatingPlacement.pivotCol:
          step.pair.pivot
        # rotor
        elif col == self.simulator[].operatingPlacement.rotorCol:
          if idx == 1:
            step.pair.rotor
          elif idx == 0 and self.simulator[].operatingPlacement.rotorDir == Up:
            step.pair.rotor
          elif idx == 2 and self.simulator[].operatingPlacement.rotorDir == Down:
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

  proc toVNode*(self: OperatingView): VNode {.inline.} =
    ## Returns the operating node.
    buildHtml table:
      tbody:
        for idx in 0 ..< 3:
          tr:
            for col in Col:
              td:
                figure(class = "image is-24x24"):
                  img(src = self.operatingCell(idx, col).cellImgSrc)
