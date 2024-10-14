## This module implements the pairs node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sugar]
import karax/[karax, karaxdsl, kbase, vdom, vstyles]
import ../[common]
import ../../[misc]
import ../../../../app/[color, nazopuyo, simulator]
import ../../../../core/[cell, pair]

func newDeleteClickHandler(simulator: ref Simulator, idx: Natural): () -> void =
  ## Returns the click handler for delete buttons.
  # NOTE: cannot inline due to lazy evaluation
  () => simulator[].deletePairPosition(idx)

func newCellClickHandler(
    simulator: ref Simulator, idx: Natural, axis: bool
): () -> void =
  ## Returns the click handler for cell buttons.
  # NOTE: cannot inline due to lazy evaluation
  () => simulator[].writeCell(idx, axis)

func cellClass(simulator: ref Simulator, idx: Natural, axis: bool): kstring {.inline.} =
  ## Returns the cell's class.
  if simulator[].pairCellBackgroundColor(idx, axis) == SelectColor:
    kstring"button p-0 is-selected is-primary"
  else:
    kstring"button p-0"

proc newPairsNode*(
    simulator: ref Simulator, displayMode = false, showPositions = true
): VNode {.inline.} =
  ## Returns the pairs node.
  let
    editMode = simulator[].mode == Edit and not displayMode
    pairsPositions = simulator[].nazoPuyoWrapBeforeMoves.get:
      wrappedNazoPuyo.puyoPuyo.pairsPositions

  result = buildHtml(table(class = "table is-narrow")):
    tbody:
      for pairIdx, pairPos in pairsPositions:
        let
          pair = pairPos.pair
          pos = simulator[].positions[pairIdx]
          rowClass =
            if simulator[].needPairPointer(pairIdx) and not displayMode:
              kstring"is-selected"
            else:
              kstring""

        tr(class = rowClass):
          # delete button
          if editMode:
            td:
              button(
                class = "button is-size-7",
                onclick = simulator.newDeleteClickHandler(pairIdx),
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-trash")

          # index
          td:
            text $pairIdx.succ

          # pair
          td:
            tdiv(class = "columns is-mobile is-gapless"):
              # axis
              tdiv(class = "column is-narrow"):
                let axisSrc = pair.axis.cellImageSrc

                if editMode:
                  button(
                    class = simulator.cellClass(pairIdx, true),
                    style = style(StyleAttr.maxHeight, kstring"24px"),
                    onclick = simulator.newCellClickHandler(pairIdx, true),
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
                    class = simulator.cellClass(pairIdx, false),
                    style = style(StyleAttr.maxHeight, kstring"24px"),
                    onclick = simulator.newCellClickHandler(pairIdx, false),
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
            text $pairsPositions.len.succ
          td:
            tdiv(class = "columns is-mobile is-gapless"):
              tdiv(class = "column is-narrow"):
                button(
                  class = simulator.cellClass(pairsPositions.len, true),
                  style = style(StyleAttr.maxHeight, kstring"24px"),
                  onclick = simulator.newCellClickHandler(pairsPositions.len, true),
                ):
                  figure(class = "image is-24x24"):
                    img(src = Cell.None.cellImageSrc)
              tdiv(class = "column is-narrow"):
                button(
                  class = simulator.cellClass(pairsPositions.len, false),
                  style = style(StyleAttr.maxHeight, kstring"24px"),
                  onclick = simulator.newCellClickHandler(pairsPositions.len, false),
                ):
                  figure(class = "image is-24x24"):
                    img(src = Cell.None.cellImageSrc)
