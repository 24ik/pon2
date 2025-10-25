## This module implements field views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karaxdsl, vdom, vstyles]
  import ../[color]
  import ../../[app]
  import ../../private/[gui]

  proc cellBgColor[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, row: Row, col: Col, editable: bool
  ): Color {.inline.} =
    ## Returns the cell's background color.
    if editable and not helper.mobile and self.derefSimulator(helper).editData.focusField and
        self.derefSimulator(helper).editData.field == (row, col):
      SelectColor
    elif row == Row.low:
      GhostColor
    elif row.ord + WaterHeight >= Height and
        self.derefSimulator(helper).nazoPuyoWrap.rule == Water:
      WaterColor
    else:
      DefaultColor

  func initBtnHandler[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, row: Row, col: Col
  ): () -> void =
    ## Returns the handler for clicking buttons.
    # NOTE: cannot inline due to karax's limitation
    () => self.derefSimulator(helper).writeCell(row, col)

  proc toFieldVNode*[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, cameraReady = false
  ): VNode {.inline.} =
    ## Returns the field node.
    let
      editable = not cameraReady and self.derefSimulator(helper).mode in EditModes
      nazoWrap = self.derefSimulator(helper).nazoPuyoWrap
      arr = nazoWrap.unwrapNazoPuyo:
        it.field.toArr
      tableBorder = (StyleAttr.border, "1px gray solid".cstring)
      tableStyle =
        if editable:
          style(
            tableBorder,
            (StyleAttr.borderCollapse, "separate".cstring),
            (StyleAttr.borderSpacing, "1px".cstring),
          )
        else:
          style(tableBorder)

    buildHtml table(style = tableStyle):
      tbody:
        for row in Row:
          tr:
            for col in Col:
              let
                imgSrc = arr[row][col].cellImgSrc
                cellStyle = style(
                  StyleAttr.backgroundColor,
                  self.cellBgColor(helper, row, col, editable).code,
                )

              td:
                if editable:
                  button(
                    class = "button p-0",
                    style = style(StyleAttr.maxHeight, "24px"),
                    onclick = self.initBtnHandler(helper, row, col),
                  ):
                    figure(class = "image is-24x24"):
                      img(src = imgSrc, style = cellStyle)
                else:
                  figure(class = "image is-24x24"):
                    img(src = imgSrc, style = cellStyle)
