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
  import chroma
  import karax/[karaxdsl, vdom, vstyles]
  import ../[helper]
  import ../../[app]
  import ../../private/[gui]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  proc cellBackgroundColor[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, row: Row, col: Col, editable: bool
  ): Color =
    ## Returns the cell's background color.
    let rule = self.derefSimulator(helper).rule

    if editable and not helper.mobile and self.derefSimulator(helper).editData.focusField and
        self.derefSimulator(helper).editData.field == (row, col):
      SelectColor
    elif row == Row.low:
      GhostColor
    elif rule == Rule.Water and row >= WaterTopRow:
      WaterColor
    else:
      let isDead =
        case Behaviours[rule].dead
        of DeadRule.Tsu:
          row == Row1 and col == Col2
        of Fever:
          row == Row1 and col in {Col2, Col3}
        of DeadRule.Water:
          row == AirBottomRow
      if isDead: DeadColor else: DefaultColor

  func initBtnHandler[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, row: Row, col: Col
  ): () -> void =
    ## Returns the handler for clicking buttons.
    () => self.derefSimulator(helper).writeCell(row, col)

  proc toFieldVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, cameraReady = false
  ): VNode =
    ## Returns the field node.
    let
      editable = not cameraReady and self.derefSimulator(helper).mode in EditModes
      cellArray = self.derefSimulator(helper).nazoPuyo.puyoPuyo.field.toArray
      tableBorder = (StyleAttr.border, "1px gray solid".kstring)
      tableStyle =
        if editable:
          style(
            tableBorder,
            (StyleAttr.borderCollapse, "separate".kstring),
            (StyleAttr.borderSpacing, "1px".kstring),
          )
        else:
          style(tableBorder)

    buildHtml table(style = tableStyle):
      tbody:
        for row in Row:
          tr:
            for col in Col:
              let
                imgSrc = cellArray[row][col].cellImgSrc
                cellStyle = style(
                  StyleAttr.backgroundColor,
                  self.cellBackgroundColor(helper, row, col, editable).toHtmlRgba.kstring,
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
