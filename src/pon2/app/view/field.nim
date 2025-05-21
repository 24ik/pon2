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
  import ../../private/app/[simulator]

type FieldView* = object ## View of the field.
  simulator: ref Simulator
  showCursor: bool

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type FieldView, simulator: ref Simulator, showCursor = true
): T {.inline.} =
  T(simulator: simulator, showCursor: showCursor)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  func cellBgColor(
      self: FieldView, row: Row, col: Col, editable: bool
  ): Color {.inline.} =
    ## Returns the cell's background color.
    if editable and self.showCursor and self.simulator[].editData.focusField and
        self.simulator[].editData.field == (row, col):
      SelectColor
    elif row == Row.low:
      GhostColor
    elif row.ord + WaterHeight >= Height and self.simulator[].nazoPuyoWrap.rule == Water:
      WaterColor
    else:
      DefaultColor

  func initBtnHandler(self: FieldView, row: Row, col: Col): () -> void =
    ## Returns the handler for clicking buttons.
    # NOTE: cannot inline due to karax's limitation
    () => self.simulator[].writeCell(row, col)

  proc toVNode*(self: FieldView, cameraReady = false): VNode {.inline.} =
    ## Returns the field node.
    let
      editable = not cameraReady and self.simulator[].mode in EditModes
      arr = self.simulator[].nazoPuyoWrap.runIt:
        it.field.toArr

    buildHtml table(style = style(StyleAttr.border, "1px black solid")):
      tbody:
        for row in Row:
          tr:
            for col in Col:
              let
                imgSrc = arr[row][col].cellImgSrc
                cellStyle = style(
                  StyleAttr.backgroundColor, self.cellBgColor(row, col, editable).code
                )

              td:
                if editable:
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
