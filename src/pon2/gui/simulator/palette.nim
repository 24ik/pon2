## This module implements the palette views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../[app]

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karax, karaxdsl, vdom, vstyles]
  import ../../[core]
  import ../../private/[gui]

type PaletteView* = object ## View of the palette.
  simulator: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type PaletteView, simulator: ref Simulator): T {.inline.} =
  T(simulator: simulator)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const
    BtnCls = "button px-2".cstring
    SelectBtnCls = "button px-2 is-selected is-primary".cstring

  func initBtnHandler(self: PaletteView, cell: Cell): () -> void =
    ## Returns the handler for clicking button.
    # NOTE: cannot inline due to karax's limitation
    () => (self.simulator[].editCell = cell)

  proc toVNode*(self: PaletteView): VNode {.inline.} =
    ## Returns the palette node.
    buildHtml table(style = style(StyleAttr.border, "1px black solid")):
      tbody:
        for cells in static(
          [
            [Cell.None, Cell.Red, Cell.Green, Cell.Blue],
            [Cell.Yellow, Cell.Purple, Garbage, Hard],
          ]
        ):
          tr:
            for cell in cells:
              td:
                button(
                  class =
                    if cell == self.simulator[].editData.cell: SelectBtnCls else: BtnCls,
                  onclick = self.initBtnHandler cell,
                ):
                  figure(class = "image is-24x24"):
                    img(src = cell.cellImgSrc)
