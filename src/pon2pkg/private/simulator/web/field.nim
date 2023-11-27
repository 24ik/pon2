## This module implements the field node.
##

{.experimental: "strictDefs".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom, vstyles]
import ./[misc]
import ../[render]
import ../../../corepkg/[field, misc]
import ../../../simulatorpkg/[simulator]

func initClickHandler(simulator: var Simulator, row: Row, col: Column):
    () -> void =
  ## Returns the click handler.
  # NOTE: cannot inline due to lazy evaluation
  () => simulator.writeCell(row, col)

proc fieldNode*(simulator: var Simulator, displayMode = false): VNode
               {.inline.} =
  ## Returns the field node.
  let arr = simulator.withField:
    field.toArray

  result = buildHtml(table(
      style = style(StyleAttr.border, kstring"1px black solid"))):
    tbody:
      for row in Row.low..Row.high:
        tr:
          for col in Column.low..Column.high:
            let cellStyle = style(
              StyleAttr.backgroundColor,
              simulator.fieldCellBackgroundColor(row, col, displayMode).
              toColorCode)
            td:
              if not displayMode and simulator.mode == Edit:
                button(class = "button p-0",
                       style = style(StyleAttr.maxHeight, kstring"24px"),
                       onclick = simulator.initClickHandler(row, col)):
                  figure(class = "image is-24x24"):
                    img(src = arr[row][col].cellImageSrc, style = cellStyle)
              else:
                figure(class = "image is-24x24"):
                  img(src = arr[row][col].cellImageSrc, style = cellStyle)
