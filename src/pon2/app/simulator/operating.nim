## This module implements operating view.
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

# TODO: better impl (draw only two cells)
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
      if it.steps[self.simulator[].operatingIdx].kind != PairPlacement:
        return Cell.None

    let pair = self.simulator[].nazoPuyoWrap.runIt:
      it.steps[self.simulator[].operatingIdx].pair

    # pivot
    if idx == 1 and col == self.simulator[].operatingPlacement.pivotCol:
      return pair.pivot

    # rotor
    if col == self.simulator[].operatingPlacement.rotorCol:
      if idx == 1:
        return pair.rotor
      if idx == 0 and self.simulator[].operatingPlacement.rotorDir == Up:
        return pair.rotor
      if idx == 2 and self.simulator[].operatingPlacement.rotorDir == Down:
        return pair.rotor

    Cell.None

  proc toVNode*(self: OperatingView): VNode {.inline.} =
    ## Returns the operating node.
    buildHtml(table):
      tbody:
        for idx in 0 ..< 3:
          tr:
            for col in Col:
              td:
                figure(class = "image is-24x24"):
                  img(src = self.operatingCell(idx, col).cellImgSrc)
