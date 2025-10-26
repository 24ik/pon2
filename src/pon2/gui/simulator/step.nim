## This module implements the steps views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[strformat, sugar]
  import chroma
  import karax/[karaxdsl, vdom, vstyles]
  import ../[helper]
  import ../../[app]
  import ../../private/[gui, utils]

  const
    CellCls = "button p-0".cstring
    SelectCellCls = "button p-0 is-primary".cstring

  func initDeleteBtnHandler[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, stepIdx: int
  ): () -> void =
    ## Returns the handler for clicking delete buttons.
    # NOTE: cannot inline due to karax's limitation
    () => self.derefSimulator(helper).deleteStep stepIdx

  func initWriteBtnHandler[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, idx: int, pivot: bool
  ): () -> void =
    ## Returns the handler for clicking write buttons.
    # NOTE: cannot inline due to karax's limitation
    () => self.derefSimulator(helper).writeCell(idx, pivot)

  func initCntSelectHandler[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, idx: int, col: Col, selectId: cstring
  ): () -> void =
    ## Returns the handler for selecting garbage cnt.
    # NOTE: cannot inline due to karax's limitation
    () => self.derefSimulator(helper).writeCnt(idx, col, selectId.getSelectedIdx)

  proc pairPlcmtCellNode[S: Simulator or Studio](
      self: ref S,
      helper: VNodeHelper,
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
          if stepHasCursor and (
            self.derefSimulator(helper).editData.step.pivot == pivot
          ): SelectCellCls else: CellCls,
        style = style(StyleAttr.maxHeight, "24px"),
        onclick = self.initWriteBtnHandler(helper, stepIdx, pivot),
      ):
        figure(class = "image is-24x24"):
          img(src = imgSrc)
    else:
      buildHtml figure(class = "image is-24x24"):
        img(src = imgSrc)

  proc pairPlcmtNode[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, step: Step, stepIdx: int, editable: bool
  ): VNode {.inline.} =
    ## Returns the pair-placement node.
    let
      stepHasCursor =
        editable and not helper.mobile and
        not self.derefSimulator(helper).editData.focusField and
        self.derefSimulator(helper).editData.step.idx == stepIdx
      nazoWrap = self.derefSimulator(helper).nazoPuyoWrap
      steps = nazoWrap.unwrapNazoPuyo:
        it.steps
      isPlaceholder = stepIdx >= steps.len
      optPlcmtDesc = (if isPlaceholder: ""
      else: $steps[stepIdx].optPlacement).cstring

    buildHtml tdiv(class = "columns is-mobile is-1"):
      # pair
      tdiv(class = "column is-narrow"):
        tdiv(class = "columns is-mobile is-gapless"):
          tdiv(class = "column is-narrow"):
            self.pairPlcmtCellNode(
              helper,
              step,
              stepIdx,
              editable,
              stepHasCursor,
              isPlaceholder,
              pivot = true,
            )
          tdiv(class = "column is-narrow"):
            self.pairPlcmtCellNode(
              helper,
              step,
              stepIdx,
              editable,
              stepHasCursor,
              isPlaceholder,
              pivot = false,
            )

      # placement
      if not isPlaceholder:
        tdiv(class = "column is-narrow"):
          text optPlcmtDesc

  proc garbagesNode[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, step: Step, stepIdx: int, editable: bool
  ): VNode {.inline.} =
    ## Returns the garbages node.
    let imgSrc = if step.dropHard: Hard.cellImgSrc else: Garbage.cellImgSrc

    buildHtml tdiv(class = "columns is-mobile is-1 is-vcentered"):
      # garbage/hard
      tdiv(class = "column is-narrow"):
        if editable:
          button(
            class = CellCls,
            style = style(StyleAttr.maxHeight, "24px"),
            onclick = () => (self.derefSimulator(helper).writeCell(stepIdx, true)),
          ):
            figure(class = "image is-24x24"):
              img(src = imgSrc)
        else:
          figure(class = "image is-24x24"):
            img(src = imgSrc)
      # cnts
      tdiv(class = "column is-narrow"):
        tdiv(
          class = (
            if helper.mobile: "columns is-mobile is-gapless"
            else: "columns is-mobile is-1"
          ).cstring
        ):
          for col in Col:
            let
              selectId =
                "pon2-simulator-step-garbagecnt-{stepIdx}-{col.ord}".fmt.cstring
              selectStyle =
                if not self.derefSimulator(helper).editData.focusField and
                    self.derefSimulator(helper).editData.step.idx == stepIdx and
                    self.derefSimulator(helper).editData.step.col == col:
                  style(StyleAttr.backgroundColor, SelectColor.toHtmlRgba.cstring)
                else:
                  style()

            tdiv(class = "column is-narrow"):
              if editable:
                tdiv(class = "select is-small"):
                  select(
                    id = selectId,
                    style = selectStyle,
                    onchange = self.initCntSelectHandler(helper, stepIdx, col, selectId),
                  ):
                    for cnt in 0 .. 9:
                      option(selected = cnt == step.cnts[col]):
                        text $cnt
              else:
                text $step.cnts[col]

  proc toStepsVNode*[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper, cameraReady = false
  ): VNode {.inline.} =
    ## Returns the steps view.
    const PlaceholderStep = Step.init

    let
      editable = self.derefSimulator(helper).mode == EditorEdit and not cameraReady
      nazoWrap = self.derefSimulator(helper).nazoPuyoWrap
      steps = nazoWrap.unwrapNazoPuyo:
        it.steps

    buildHtml table(class = "table is-narrow"):
      tbody:
        for stepIdx, step in steps:
          let rowCls =
            if not editable and self.derefSimulator(helper).state == Stable and
                self.derefSimulator(helper).operatingIdx == stepIdx:
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
                      onclick = self.initDeleteBtnHandler(helper, stepIdx),
                    ):
                      span(class = "icon"):
                        italic(class = "fa-solid fa-trash")

                tdiv(class = "column is-narrow"):
                  bold:
                    text $stepIdx.succ

                # step
                tdiv(class = "column is-narrow"):
                  case step.kind
                  of PairPlacement:
                    self.pairPlcmtNode(helper, step, stepIdx, editable)
                  of StepKind.Garbages:
                    self.garbagesNode(helper, step, stepIdx, editable)

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
                  bold:
                    text $placeholderIdx.succ

                tdiv(class = "column is-narrow"):
                  self.pairPlcmtNode(helper, PlaceholderStep, placeholderIdx, editable)
