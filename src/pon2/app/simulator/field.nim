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
import ../[color, nazopuyowrap, simulator]
import ../../[core]
import ../../private/[staticfor2]
import ../../private/app/simulator/[common]

type FieldView = object ## View of the field.
  simulator: ref Simulator

  displayMode: bool

  editing: bool
  selectRow: Row
  selectCol: Col

func cellBgColor(
    self: FieldView, row: static Row, col: static Col, displayMode = false
): Color {.inline.} =
  ## Returns the cell's background color.
  when row == Row.low:
    GhostColor
  else:
    if static(row.ord + WaterHeight >= Height) and
        self.simulator.nazoPuyoWrap.rule == Water:
      WaterColor
    elif isMobile() or displayMode:
      DefaultColor
    elif editing and row == self.selectRow and col == self.selectCol:
      SelectColor
    else:
      DefaultColor

func newClickHandler(simulator: Simulator, row: Row, col: Column): () -> void =
  ## Returns the click handler.
  # NOTE: cannot inline due to lazy evaluation
  () => simulator.writeCell(row, col)

proc toVNode*(self: FieldView): VNode {.inline.} =
  ## Returns the field node.
  let arr = self.simulator.nazoPuyoWrap.runIt:
    it.field.toArr

  buildHtml(table(style = style(StyleAttr.border, "1px black solid".kstring))):
    tbody:
      staitcFor(row, Row):
        tr:
          staticFor(col, Col):
            let
              imgSrc = arr[row][col].cellImgSrc
              cellStyle = style(
                StyleAttr.backgroundColor,
                simulator.cellBgColor(row, col, displayMode).code,
              )

            td:
              if not displayMode and simulator.mode == Edit:
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
