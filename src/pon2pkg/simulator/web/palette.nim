## This module implements the palette frame.
##

{.experimental: "strictDefs".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom, vstyles]
import ./[misc]
import ../[simulator]
import ../../core/[cell]

const
  ButtonClass = kstring"button px-2"
  SelectedButtonClass = kstring"button px-2 is-selected is-primary"

func initClickHandler(simulator: var Simulator, cell: Cell): () -> void =
  ## Returns the click handler.
  # NOTE: inline handler does not work (due to Karax's specifications)
  () => (simulator.selectingCell = cell)

proc paletteFrame*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the palette frame.
  buildHtml(tdiv):
    table(style = style(StyleAttr.border, kstring"1px black solid")):
      tbody:
        tr:
          for cell in [None, Red, Green, Blue]:
            td:
              button(
                class =
                  if cell == simulator.selectingCell: SelectedButtonClass
                  else: ButtonClass,
                onclick = simulator.initClickHandler(cell),
              ):
                figure(class = "image is-24x24"):
                  img(src = cell.cellImageSrc)
        tr:
          for i, cell in [Cell.Yellow, Purple, Garbage]:
            td:
              button(
                class =
                  if cell == simulator.selectingCell: SelectedButtonClass
                  else: ButtonClass,
                onclick = simulator.initClickHandler(cell),
              ):
                figure(class = "image is-24x24"):
                  img(src = cell.cellImageSrc)
