## This module implements the palette node.
##

{.experimental: "strictDefs".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom, vstyles]
import ./[misc]
import ../../../corepkg/[cell]
import ../../../simulatorpkg/[simulator]

const
  ButtonClass = kstring"button px-2"
  SelectedButtonClass = kstring"button px-2 is-selected is-primary"

func initClickHandler(simulator: var Simulator, cell: Cell): () -> void =
  ## Returns the click handler.
  # NOTE: cannot inline due to lazy evaluation
  () => (simulator.editing.cell = cell)

proc paletteNode*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the palette node.
  buildHtml(tdiv):
    table(style = style(StyleAttr.border, kstring"1px black solid")):
      tbody:
        tr:
          for cell in [None, Red, Green, Blue]:
            td:
              button(
                  class =
                    if cell == simulator.editing.cell: SelectedButtonClass
                    else: ButtonClass,
                  onclick = simulator.initClickHandler(cell)):
                figure(class = "image is-24x24"):
                  img(src = cell.cellImageSrc)
        tr:
          for i, cell in [Yellow, Purple, Garbage]:
            td:
              button(
                  class =
                    if cell == simulator.editing.cell: SelectedButtonClass
                    else: ButtonClass,
                  onclick = simulator.initClickHandler(cell)):
                figure(class = "image is-24x24"):
                  img(src = cell.cellImageSrc)
