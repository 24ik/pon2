## This module implements the palette node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom, vstyles]
import ../../[misc]
import ../../../../app/[simulator]
import ../../../../core/[cell]

const
  ButtonClass = kstring"button px-2"
  SelectedButtonClass = kstring"button px-2 is-selected is-primary"

func newClickHandler(simulator: Simulator, cell: Cell): () -> void =
  ## Returns the click handler.
  # NOTE: cannot inline due to lazy evaluation
  () => (simulator.editingCell = cell)

proc newPaletteNode*(simulator: Simulator): VNode {.inline.} =
  ## Returns the palette node.
  buildHtml(tdiv):
    table(style = style(StyleAttr.border, kstring"1px black solid")):
      tbody:
        tr:
          for cell in [None, Red, Green, Blue]:
            td:
              let cellClass =
                if cell == simulator.editing.cell: SelectedButtonClass else: ButtonClass

              button(class = cellClass, onclick = simulator.newClickHandler(cell)):
                figure(class = "image is-24x24"):
                  img(src = cell.cellImageSrc)
        tr:
          for i, cell in [Yellow, Purple, Garbage]:
            td:
              let cellClass =
                if cell == simulator.editing.cell: SelectedButtonClass else: ButtonClass

              button(class = cellClass, onclick = simulator.newClickHandler(cell)):
                figure(class = "image is-24x24"):
                  img(src = cell.cellImageSrc)
