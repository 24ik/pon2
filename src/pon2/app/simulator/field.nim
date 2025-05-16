## This module implements field views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karax, karaxdsl, vdom, vstyles]
  import ../[color, nazopuyowrap, simulator]
  import ../../[core]
  import ../../private/app/simulator/[common]

type FieldView* = object ## View of the field.
  simulator: ref Simulator
  enableCursor: bool
  displayMode: bool

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type FieldView,
    simulator: ref Simulator,
    enableCursor = true,
    displayMode = false,
): T {.inline.} =
  T(simulator: simulator, enableCursor: enableCursor, displayMode: displayMode)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  func cellBgColor(self: FieldView, row: Row, col: Col): Color {.inline.} =
    ## Returns the cell's background color.
    if row == Row.low:
      GhostColor
    else:
      if row.ord + WaterHeight >= Height and self.simulator[].nazoPuyoWrap.rule == Water:
        WaterColor
      elif not self.enableCursor or self.displayMode:
        DefaultColor
      elif self.simulator[].mode in EditModes and self.simulator[].editData.focusField and
          self.simulator[].editData.field == (row, col):
        SelectColor
      else:
        DefaultColor

  func initBtnHandler(self: FieldView, row: Row, col: Col): () -> void =
    ## Returns the handler for clicking button.
    () => self.simulator[].writeCell(row, col)

  proc toVNode*(self: FieldView): VNode {.inline.} =
    ## Returns the field node.
    let arr = self.simulator[].nazoPuyoWrap.runIt:
      it.field.toArr

    buildHtml(table(style = style(StyleAttr.border, "1px black solid"))):
      tbody:
        for row in Row:
          tr:
            for col in Col:
              let
                imgSrc = arr[row][col].cellImgSrc
                cellStyle =
                  style(StyleAttr.backgroundColor, self.cellBgColor(row, col).code)

              td:
                if not self.displayMode and self.simulator[].mode in EditModes:
                  button(
                    class = "button p-0",
                    style = style(StyleAttr.maxHeight, "24px"),
                    onclick = self.initBtnHandler(row, col),
                  ):
                    figure(class = "image is-24x24"):
                      img(src = imgSrc, style = cellStyle)
                else:
                  figure(class = "image is-24x24"):
                    img(src = imgSrc, style = cellStyle)
