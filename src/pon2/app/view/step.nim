## This module implements the steps views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import std/[strformat, sugar]
  import karax/[karax, karaxdsl, vdom, vstyles]
  import ../[color, nazopuyowrap, simulator]
  import ../../[core]
  import ../../private/[utils]
  import ../../private/app/[simulator]

type StepsView* = object ## View of the steps.
  simulator: ref Simulator
  showCursor: bool

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type StepsView, simulator: ref Simulator, showCursor = true
): T {.inline.} =
  T(simulator: simulator, showCursor: showCursor)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const
    CellCls = "button p-0".cstring
    SelectCellCls = "button p-0 is-selected is-primary".cstring
    GarbageCntSelectIdPrefix = "pon2-simulator-step-garbagecnt-".cstring

  func initDeleteBtnHandler(self: StepsView, stepIdx: int): () -> void =
    ## Returns the handler for clicking delete buttons.
    # NOTE: cannot inline due to karax's limitation
    () => self.simulator[].deleteStep stepIdx

  func initWriteBtnHandler(self: StepsView, idx: int, pivot: bool): () -> void =
    ## Returns the handler for clicking write buttons.
    # NOTE: cannot inline due to karax's limitation
    () => self.simulator[].writeCell(idx, pivot)

  func initCntSelectHandler(
      self: StepsView, idx: int, col: Col, selectId: cstring
  ): () -> void =
    ## Returns the handler for selecting garbage cnt.
    # NOTE: cannot inline due to karax's limitation
    () => self.simulator[].writeCnt(idx, col, selectId.getSelectedIdx)

  proc pairPlcmtCellNode(
      self: StepsView,
      step: Step,
      stepIdx: int,
      editable, stepHasCursor, isPlaceholder, pivot: bool,
  ): VNode {.inline.} =
    ## Returns the cell node in the pair-placement step.
    let imgSrc =
      if isPlaceholder:
        Cell.None.cellImgSrc
      elif pivot:
        step.pair.pivot.cellImgSrc
      else:
        step.pair.rotor.cellImgSrc

    if editable:
      buildHtml button(
        class =
          if stepHasCursor and (self.simulator[].editData.step.pivot == pivot):
            SelectCellCls
          else:
            CellCls,
        style = style(StyleAttr.maxHeight, "24px"),
        onclick = self.initWriteBtnHandler(stepIdx, pivot),
      ):
        figure(class = "image is-24x24"):
          img(src = imgSrc)
    else:
      buildHtml figure(class = "image is-24x24"):
        img(src = imgSrc)

  proc pairPlcmtNode(
      self: StepsView, step: Step, stepIdx: int, editable: bool
  ): VNode {.inline.} =
    ## Returns the pair-placement node.
    let
      stepHasCursor =
        editable and self.showCursor and not self.simulator[].editData.focusField and
        self.simulator[].editData.step.idx == stepIdx
      optPlcmtDesc: cstring
      isPlaceholder: bool
    self.simulator[].nazoPuyoWrap.runIt:
      isPlaceholder = stepIdx >= it.steps.len

      if isPlaceholder:
        optPlcmtDesc = "" # NOTE: dummy to compile
      else:
        optPlcmtDesc = cstring $it.steps[stepIdx].optPlacement

    buildHtml tdiv(class = "columns is-mobile is-1"):
      # pair
      tdiv(class = "column is-narrow"):
        tdiv(class = "columns is-mobile is-gapless"):
          tdiv(class = "column is-narrow"):
            self.pairPlcmtCellNode(
              step, stepIdx, editable, stepHasCursor, isPlaceholder, pivot = true
            )
          tdiv(class = "column is-narrow"):
            self.pairPlcmtCellNode(
              step, stepIdx, editable, stepHasCursor, isPlaceholder, pivot = false
            )

      # placement
      if not isPlaceholder:
        tdiv(class = "column is-narrow"):
          text optPlcmtDesc

  proc garbagesNode(
      self: StepsView, step: Step, stepIdx: int, editable: bool
  ): VNode {.inline.} =
    ## Returns the garbages node.
    let
      cntsColsCls =
        if editable: "columns is-mobile is-gapless" else: "columns is-mobile is-1"
      imgSrc = if step.dropHard: Hard.cellImgSrc else: Garbage.cellImgSrc

    buildHtml tdiv(class = "columns is-mobile is-1 is-vcentered"):
      # garbage/hard
      tdiv(class = "column is-narrow"):
        if editable:
          button(
            class = CellCls,
            style = style(StyleAttr.maxHeight, "24px"),
            onclick = () => (self.simulator[].writeCell(stepIdx, true)),
          ):
            figure(class = "image is-24x24"):
              img(src = imgSrc)
        else:
          figure(class = "image is-24x24"):
            img(src = imgSrc)
      # cnts
      tdiv(class = "column is-narrow"):
        tdiv(class = cntsColsCls):
          for col in Col:
            let
              selectId = "{GarbageCntSelectIdPrefix}{stepIdx}-{col.ord}".fmt.cstring
              selectStyle =
                if not self.simulator[].editData.focusField and
                    self.simulator[].editData.step.idx == stepIdx and
                    self.simulator[].editData.step.col == col:
                  style(StyleAttr.backgroundColor, SelectColor.code)
                else:
                  style()

            tdiv(class = "column is-narrow"):
              if editable:
                tdiv(class = "select is-small"):
                  select(
                    id = selectId,
                    style = selectStyle,
                    onchange = self.initCntSelectHandler(stepIdx, col, selectId),
                  ):
                    for cnt in 0 .. 9:
                      option(selected = cnt == step.cnts[col]):
                        text $cnt
              else:
                bold:
                  text $step.cnts[col]

  proc toVNode*(self: StepsView, cameraReady = false): VNode {.inline.} =
    ## Returns the steps view.
    const DummyStep = Step.init

    let
      editable = self.simulator[].mode == EditorEdit and not cameraReady
      steps = self.simulator[].nazoPuyoWrap.runIt:
        it.steps

    buildHtml table(class = "table is-narrow"):
      tbody:
        for stepIdx, step in steps:
          let rowCls =
            if not editable and self.simulator[].state == Stable and
                self.simulator[].operatingIdx == stepIdx:
              "is-selected".cstring
            else:
              "".cstring

          tr(class = rowCls):
            td:
              tdiv(class = "columns is-mobile is-vcentered"):
                # delete button
                if editable:
                  tdiv(class = "column is-narrow"):
                    button(
                      class = "button is-size-7",
                      onclick = self.initDeleteBtnHandler stepIdx,
                    ):
                      span(class = "icon"):
                        italic(class = "fa-solid fa-trash")

                tdiv(class = "column is-narrow"):
                  text $stepIdx.succ

                # step
                tdiv(class = "column is-narrow"):
                  case step.kind
                  of PairPlacement:
                    self.pairPlcmtNode(step, stepIdx, editable)
                  of StepKind.Garbages:
                    self.garbagesNode(step, stepIdx, editable)

        # placeholder after the last step
        if editable:
          let placeholderIdx = steps.len

          tr:
            td:
              tdiv(class = "columns is-mobile"):
                # hidden placeholder to align
                tdiv(class = "column is-narrow"):
                  button(
                    class = "button is-size-7 is-static",
                    style = style(StyleAttr.visibility, "hidden"),
                  ):
                    span(class = "icon"):
                      italic(class = "fa-solid fa-trash")

                tdiv(class = "column is-narrow"):
                  text $placeholderIdx.succ

                tdiv(class = "column is-narrow"):
                  self.pairPlcmtNode(DummyStep, placeholderIdx, editable)
