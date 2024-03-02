## This module implements the pairs node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom, vstyles]
import ../[common]
import ../../[misc]
import ../../../../app/[color, nazopuyo, simulator]
import ../../../../core/[cell, pair]

func initDeleteClickHandler(simulator: var Simulator, idx: Natural): () -> void =
  ## Returns the click handler for delete buttons.
  # NOTE: cannot inline due to lazy evaluation
  () => simulator.deletePairPosition(idx)

func initCellClickHandler(
    simulator: var Simulator, idx: Natural, axis: bool
): () -> void =
  ## Returns the click handler for cell buttons.
  # NOTE: cannot inline due to lazy evaluation
  () => simulator.writeCell(idx, axis)

func cellClass(simulator: Simulator, idx: Natural, axis: bool): kstring {.inline.} =
  ## Returns the cell's class.
  if simulator.pairCellBackgroundColor(idx, axis) == SelectColor:
    kstring"button p-0 is-selected is-primary"
  else:
    kstring"button p-0"

proc initPairsNode*(
    simulator: var Simulator, displayMode = false, showPositions = true
): VNode {.inline.} =
  ## Returns the pairs node.
  let editMode = simulator.mode == Edit and not displayMode

  result = buildHtml(table(class = "table is-narrow")):
    tbody:
      for idx, pairPos in simulator.nazoPuyoWrap.pairsPositions:
        let
          pair = pairPos.pair
          pos = pairPos.position
          rowClass =
            if simulator.needPairPointer(idx) and not displayMode:
              kstring"is-selected"
            else:
              kstring""

        tr(class = rowClass):
          # delete button
          if editMode:
            td:
              button(
                class = "button is-size-7",
                onclick = simulator.initDeleteClickHandler(idx),
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-trash")

          # index
          td:
            text $idx.succ

          # pair
          td:
            tdiv(class = "columns is-mobile is-gapless"):
              # axis
              tdiv(class = "column is-narrow"):
                let axisSrc = pair.axis.cellImageSrc

                if editMode:
                  button(
                    class = simulator.cellClass(idx, true),
                    style = style(StyleAttr.maxHeight, kstring"24px"),
                    onclick = simulator.initCellClickHandler(idx, true),
                  ):
                    figure(class = "image is-24x24"):
                      img(src = axisSrc)
                else:
                  figure(class = "image is-24x24"):
                    img(src = axisSrc)
              # child
              tdiv(class = "column is-narrow"):
                let childSrc = pair.child.cellImageSrc

                if editMode:
                  button(
                    class = simulator.cellClass(idx, false),
                    style = style(StyleAttr.maxHeight, kstring"24px"),
                    onclick = simulator.initCellClickHandler(idx, false),
                  ):
                    figure(class = "image is-24x24"):
                      img(src = childSrc)
                else:
                  figure(class = "image is-24x24"):
                    img(src = childSrc)

          # position
          if showPositions:
            td:
              text $pos

      # placeholder after the last pair for edit mode
      if editMode:
        tr:
          td:
            button(
              class = "button is-static",
              style = style(StyleAttr.visibility, kstring"hidden"),
            ):
              span(class = "icon"):
                italic(class = "fa-solid fa-trash")
          td:
            text $simulator.originalNazoPuyoWrap.pairsPositions.len.succ
          td:
            tdiv(class = "columns is-mobile is-gapless"):
              tdiv(class = "column is-narrow"):
                button(
                  class = simulator.cellClass(
                    simulator.originalNazoPuyoWrap.pairsPositions.len, true
                  ),
                  style = style(StyleAttr.maxHeight, kstring"24px"),
                  onclick = simulator.initCellClickHandler(
                    simulator.originalNazoPuyoWrap.pairsPositions.len, true
                  ),
                ):
                  figure(class = "image is-24x24"):
                    img(src = Cell.None.cellImageSrc)
              tdiv(class = "column is-narrow"):
                button(
                  class = simulator.cellClass(
                    simulator.originalNazoPuyoWrap.pairsPositions.len, false
                  ),
                  style = style(StyleAttr.maxHeight, kstring"24px"),
                  onclick = simulator.initCellClickHandler(
                    simulator.originalNazoPuyoWrap.pairsPositions.len, false
                  ),
                ):
                  figure(class = "image is-24x24"):
                    img(src = Cell.None.cellImageSrc)
