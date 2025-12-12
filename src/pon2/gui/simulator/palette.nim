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

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  const Shortcuts: array[Cell, kstring] = [
    "Space".kstring, "P".kstring, "O".kstring, "H".kstring, "J".kstring, "K".kstring,
    "L".kstring, ";".kstring,
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
  ): VNode =
    ## Returns the palette node.
    let
      editObj = self.derefSimulator(helper).editData.editObj
      btnClass = (if helper.mobile: "button is-large px-2" else: "button px-2").kstring
      selectBtnClass = (
        if helper.mobile: "button is-large is-primary px-2"
        else: "button px-2 is-primary"
      ).kstring

    buildHtml tdiv(class = "card", style = translucentStyle):
      tdiv(class = "card-content p-1"):
        table:
          tbody:
            for row, cells in [
              [Cell.None, Cell.Red, Cell.Green, Cell.Blue],
              [Cell.Yellow, Cell.Purple, Garbage, Hard],
            ]:
              tr:
                for cell in cells:
                  let cellSelected = editObj.kind == EditCell and editObj.cell == cell
                  td:
                    button(
                      class = if cellSelected: selectBtnClass else: btnClass,
                      onclick = self.initBtnHandler(helper, cell),
                    ):
                      figure(
                        class = (
                          if helper.mobile: "image is-32x32" else: "image is-24x24"
                        ).kstring
                      ):
                        img(src = cell.cellImgSrc)
                      if not helper.mobile and not cellSelected:
                        span(style = counterStyle):
                          text ShortCuts[cell]
                td:
                  let
                    cross = row.bool
                    selected = editObj.kind == EditRotate and editObj.cross == cross
                  button(
                    class = if selected: selectBtnClass else: btnClass,
                    disabled = row != self.derefSimulator(helper).rule.ord.pred,
                    onclick = self.initBtnHandler(helper, cross),
                  ):
                    figure(
                      class = (
                        if helper.mobile: "image is-32x32" else: "image is-24x24"
                      ).kstring
                    ):
                      span(
                        class =
                          (if helper.mobile: "icon is-medium" else: "icon").kstring
                      ):
                        if cross:
                          span(
                            class = "fa-stack",
                            style = style(StyleAttr.fontSize, "0.5em"),
                          ):
                            italic(class = "fa-solid fa-arrows-rotate fa-stack-2x")
                            italic(class = "fa-solid fa-c fa-stack-1x")
                        else:
                          italic(class = "fa-solid fa-arrows-rotate")
                    if not helper.mobile and not selected:
                      span(style = counterStyle):
                        text (if cross: "M" else: "N").kstring
