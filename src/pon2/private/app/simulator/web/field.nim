## This module implements the field node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom, vstyles]
import ../[common]
import ../../[misc]
import ../../../../app/[color, nazopuyo, simulator]
import ../../../../core/[cell, field, fieldtype]

func newClickHandler(simulator: ref Simulator, row: Row, col: Column): () -> void =
  ## Returns the click handler.
  # NOTE: cannot inline due to lazy evaluation
  () => simulator[].writeCell(row, col)

proc newFieldNode*(simulator: ref Simulator, displayMode = false): VNode {.inline.} =
  ## Returns the field node.
  let arr: array[Height, array[Width, Cell]]
  simulator[].nazoPuyoWrap.get:
    arr = wrappedNazoPuyo.puyoPuyo.field.toArray

  result = buildHtml(table(style = style(StyleAttr.border, kstring"1px black solid"))):
    tbody:
      for row in Row.low .. Row.high:
        tr:
          for col in Column.low .. Column.high:
            let
              imgSrc = arr[row][col].cellImageSrc
              cellStyle = style(
                StyleAttr.backgroundColor,
                simulator[].fieldCellBackgroundColor(row, col, displayMode).toColorCode,
              )

            td:
              if not displayMode and simulator[].mode == Edit:
                button(
                  class = "button p-0",
                  style = style(StyleAttr.maxHeight, kstring"24px"),
                  onclick = simulator.newClickHandler(row, col),
                ):
                  figure(class = "image is-24x24"):
                    img(src = imgSrc, style = cellStyle)
              else:
                figure(class = "image is-24x24"):
                  img(src = imgSrc, style = cellStyle)
