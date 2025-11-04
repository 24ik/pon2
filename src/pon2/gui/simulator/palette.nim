## This module implements the palette views.
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
  import ../[helper]
  import ../../[app]
  import ../../private/[gui]

  const
    BtnCls = "button px-2".cstring
    SelectBtnCls = "button px-2 is-primary".cstring
    Shortcuts: array[Cell, cstring] = [
      "Space".cstring, "P".cstring, "O".cstring, "H".cstring, "J".cstring, "K".cstring,
      "L".cstring, ";".cstring,
    ]

  func initBtnHandler[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, cell: Cell
  ): () -> void =
    ## Returns the handler for clicking button.
    # NOTE: cannot inline due to karax's limitation
    () => (self.derefSimulator(helper).editCell = cell)

  func initBtnHandler[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, cross: bool
  ): () -> void =
    ## Returns the handler for clicking button.
    # NOTE: cannot inline due to karax's limitation
    () => (self.derefSimulator(helper).editCross = cross)

  proc toPaletteVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): VNode {.inline.} =
    ## Returns the palette node.
    let editObj = self.derefSimulator(helper).editData.editObj

    buildHtml tdiv(class = "card", style = translucentStyle):
      tdiv(class = "card-content p-1"):
        table:
          tbody:
            for row, cells in static(
              [
                [Cell.None, Cell.Red, Cell.Green, Cell.Blue],
                [Cell.Yellow, Cell.Purple, Garbage, Hard],
              ]
            ):
              tr:
                for cell in cells:
                  let cellSelected = editObj.kind == EditCell and editObj.cell == cell
                  td:
                    button(
                      class = if cellSelected: SelectBtnCls else: BtnCls,
                      onclick = self.initBtnHandler(helper, cell),
                    ):
                      figure(class = "image is-24x24"):
                        img(src = cell.cellImgSrc)
                      if not helper.mobile and not cellSelected:
                        span(style = counterStyle):
                          text ShortCuts[cell]
                td:
                  let
                    cross = row.bool
                    selected = editObj.kind == EditRotate and editObj.cross == cross
                  button(
                    class = if selected: SelectBtnCls else: BtnCls,
                    onclick = self.initBtnHandler(helper, cross),
                  ):
                    figure(class = "image is-24x24"):
                      span(class = "icon"):
                        if cross:
                          span(
                            class = "fa-stack",
                            style = style(StyleAttr.fontSize, "0.5em"),
                          ):
                            italic(class = "fa-solid fa-arrows-rotate fa-stack-2x")
                            italic(class = "fa-solid fa-xmark fa-stack-1x")
                        else:
                          italic(class = "fa-solid fa-arrows-rotate")
                    if not helper.mobile and not selected:
                      span(style = counterStyle):
                        text (if cross: "M" else: "N").cstring
