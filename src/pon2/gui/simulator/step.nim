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
  import ../../private/[dom, gui, utils]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  const
    CellClass = "button p-0".kstring
    SelectCellClass = "button p-0 is-primary".kstring

  func initDelBtnHandler[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, stepIndex: int
  ): () -> void =
    ## Returns the handler for clicking del buttons.
    # NOTE: cannot inline due to karax's limitation
    () => self.derefSimulator(helper).delStep stepIndex

  func initWriteBtnHandler[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, index: int, pivot: bool
  ): () -> void =
    ## Returns the handler for clicking write buttons.
    # NOTE: cannot inline due to karax's limitation
    () => self.derefSimulator(helper).writeCell(index, pivot)

  func initCountSelectHandler[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, index: int, col: Col, selectId: kstring
  ): () -> void =
    ## Returns the handler for selecting garbage counts.
    # NOTE: cannot inline due to karax's limitation
    () => self.derefSimulator(helper).writeCount(index, col, selectId.getSelectedIndex)

  proc pairPlcmtCellNode[S: Simulator or Studio or Marathon](
      self: ref S,
      helper: VNodeHelper,
      step: Step,
      stepIndex: int,
      editable, stepHasCursor, isPlaceholder, pivot: bool,
  ): VNode =
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
          if stepHasCursor and
              (self.derefSimulator(helper).editData.steps.pivot == pivot):
            SelectCellClass
          else:
            CellClass,
        style = style(StyleAttr.maxHeight, "24px"),
        onclick = self.initWriteBtnHandler(helper, stepIndex, pivot),
      ):
        figure(class = "image is-24x24"):
          img(src = imgSrc)
    else:
      buildHtml figure(class = "image is-24x24"):
        img(src = imgSrc)

  proc pairPlcmtNode[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, step: Step, stepIndex: int, editable: bool
  ): VNode =
    ## Returns the pair-placement node.
    let
      stepHasCursor =
        editable and not helper.mobile and
        not self.derefSimulator(helper).editData.focusField and
        self.derefSimulator(helper).editData.steps.index == stepIndex
      steps = self.derefSimulator(helper).nazoPuyo.puyoPuyo.steps
      isPlaceholder = stepIndex >= steps.len
      optPlcmtDesc = (if isPlaceholder: "" else: $steps[stepIndex].placement).kstring

    buildHtml tdiv(class = "columns is-mobile is-1"):
      # pair
      tdiv(class = "column is-narrow"):
        tdiv(class = "columns is-mobile is-gapless"):
          tdiv(class = "column is-narrow"):
            self.pairPlcmtCellNode(
              helper,
              step,
              stepIndex,
              editable,
              stepHasCursor,
              isPlaceholder,
              pivot = true,
            )
          tdiv(class = "column is-narrow"):
            self.pairPlcmtCellNode(
              helper,
              step,
              stepIndex,
              editable,
              stepHasCursor,
              isPlaceholder,
              pivot = false,
            )

      # placement
      if not isPlaceholder:
        tdiv(class = "column is-narrow"):
          text optPlcmtDesc

  proc garbagesNode[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, step: Step, stepIndex: int, editable: bool
  ): VNode =
    ## Returns the garbages node.
    let imgSrc = if step.hard: Hard.cellImgSrc else: Garbage.cellImgSrc

    buildHtml tdiv(class = "columns is-mobile is-1 is-vcentered"):
      # garbage/hard
      tdiv(class = "column is-narrow"):
        if editable:
          button(
            class = CellClass,
            style = style(StyleAttr.maxHeight, "24px"),
            onclick = () => (self.derefSimulator(helper).writeCell(stepIndex, true)),
          ):
            figure(class = "image is-24x24"):
              img(src = imgSrc)
        else:
          figure(class = "image is-24x24"):
            img(src = imgSrc)
      # counts
      tdiv(class = "column is-narrow"):
        tdiv(
          class = (
            if helper.mobile: "columns is-mobile is-gapless"
            else: "columns is-mobile is-1"
          ).kstring
        ):
          for col in Col:
            let
              selectId =
                "pon2-simulator-step-garbagecount-{stepIndex}-{col.ord}".fmt.kstring
              selectStyle =
                if not self.derefSimulator(helper).editData.focusField and
                    self.derefSimulator(helper).editData.steps.index == stepIndex and
                    self.derefSimulator(helper).editData.steps.col == col:
                  style(StyleAttr.backgroundColor, SelectColor.toHtmlRgba.kstring)
                else:
                  style()

            tdiv(class = "column is-narrow"):
              if editable:
                tdiv(class = "select is-small"):
                  select(
                    id = selectId,
                    style = selectStyle,
                    onchange =
                      self.initCountSelectHandler(helper, stepIndex, col, selectId),
                  ):
                    for count in 0 .. 9:
                      option(selected = count == step.counts[col]):
                        text ($count).kstring
              else:
                text ($step.counts[col]).kstring

  proc rotateNode[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, step: Step, stepIndex: int, editable: bool
  ): VNode =
    ## Returns the rotate node.
    let icon = buildHtml span(class = "icon"):
      if step.cross:
        span(class = "fa-stack", style = style(StyleAttr.fontSize, "0.5em")):
          italic(class = "fa-solid fa-arrows-rotate fa-stack-2x")
          italic(class = "fa-solid fa-c fa-stack-1x")
      else:
        italic(class = "fa-solid fa-arrows-rotate")

    if editable:
      buildHtml button(
        class = (
          if not helper.mobile and not self.derefSimulator(helper).editData.focusField and
              self.derefSimulator(helper).editData.steps.index == stepIndex:
          "button is-size-7 is-primary"
          else: "button is-size-7"
        ).kstring,
        onclick = () => (self.derefSimulator(helper).writeCell(stepIndex, true)),
      ):
        icon
    else:
      icon

  proc toStepsVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, cameraReady = false
  ): VNode =
    ## Returns the steps view.
    const PlaceholderStep = Step.init

    let
      editable = self.derefSimulator(helper).mode == EditEditor and not cameraReady
      steps = self.derefSimulator(helper).nazoPuyo.puyoPuyo.steps

    buildHtml table(class = "table is-narrow"):
      tbody:
        for stepIndex, step in steps:
          let rowClass = (
            if not editable and self.derefSimulator(helper).state == Stable and
                self.derefSimulator(helper).operating.index == stepIndex:
              "is-selected"
            else:
              ""
          ).kstring

          tr(class = rowClass):
            td:
              tdiv(class = "columns is-mobile is-vcentered"):
                # delete button
                if editable:
                  tdiv(class = "column is-narrow"):
                    button(
                      class = "button is-size-7",
                      onclick = self.initDelBtnHandler(helper, stepIndex),
                    ):
                      span(class = "icon"):
                        italic(class = "fa-solid fa-trash")

                tdiv(class = "column is-narrow"):
                  bold:
                    text ($stepIndex.succ).kstring

                # step
                tdiv(class = "column is-narrow"):
                  case step.kind
                  of PairPlace:
                    self.pairPlcmtNode(helper, step, stepIndex, editable)
                  of NuisanceDrop:
                    self.garbagesNode(helper, step, stepIndex, editable)
                  of FieldRotate:
                    self.rotateNode(helper, step, stepIndex, editable)

        # placeholder after the last step
        if editable:
          let placeholderIndex = steps.len

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
                    text ($placeholderIndex.succ).kstring

                tdiv(class = "column is-narrow"):
                  self.pairPlcmtNode(
                    helper, PlaceholderStep, placeholderIndex, editable
                  )
