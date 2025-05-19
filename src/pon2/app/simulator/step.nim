## This module implements the steps views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karax, karaxdsl, vdom, vstyles]
  import ../[nazopuyowrap, simulator]
  import ../../[core]
  import ../../private/app/simulator/[common]

type StepsView* = object ## View of the steps.
  simulator: ref Simulator
  enableCursor: bool
  displayMode: bool

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type StepsView,
    simulator: ref Simulator,
    enableCursor = true,
    displayMode = false,
): T {.inline.} =
  T(simulator: simulator, enableCursor: enableCursor, displayMode: displayMode)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const
    SelectCellCls = "button p-0 is-selected is-primary".cstring
    NotSelectCellCls = "button p-0".cstring

  func initDeleteBtnHandler(self: StepsView, stepIdx: int): () -> void =
    ## Returns the handler for clicking delete buttons.
    # NOTE: cannot inline due to karax's limitation
    () => self.simulator[].deleteStep stepIdx

  func initWriteBtnHandler(self: StepsView, idx: int, pivot: bool): () -> void =
    ## Returns the handler for clicking write buttons.
    # NOTE: cannot inline due to karax's limitation
    () => self.simulator[].writeCell(idx, pivot)

  proc pairPlcmtNode(self: StepsView, stepIdx: int, editable: bool): VNode {.inline.} =
    ## Returns the pair-placement node.
    let
      isCursorShownStep =
        self.enableCursor and not self.simulator[].editData.focusField and
        self.simulator[].editData.step.idx == stepIdx
      pivotSrc, rotorSrc, optPlcmtDesc: cstring
      isPlaceholder: bool
    self.simulator[].nazoPuyoWrap.runIt:
      isPlaceholder = stepIdx >= it.steps.len

      if isPlaceholder:
        pivotSrc = Cell.None.cellImgSrc
        rotorSrc = Cell.None.cellImgSrc
        optPlcmtDesc = "" # NOTE: dummy to compile
      else:
        let pair = it.steps[stepIdx].pair
        pivotSrc = pair.pivot.cellImgSrc
        rotorSrc = pair.rotor.cellImgSrc
        optPlcmtDesc = cstring $it.steps[stepIdx].optPlacement

    buildHtml tdiv(class = "columns is-mobile is-gapless"):
      # pivot
      tdiv(class = "column is-narrow"):
        if editable:
          button(
            class =
              if isCursorShownStep and self.simulator[].editData.step.pivot:
                SelectCellCls
              else:
                NotSelectCellCls,
            style = style(StyleAttr.maxHeight, "24px"),
            onclick = self.initWriteBtnHandler(stepIdx, true),
          ):
            figure(class = "image is-24x24"):
              img(src = pivotSrc)
        else:
          figure(class = "image is-24x24"):
            img(src = pivotSrc)
      # rotor
      tdiv(class = "column is-narrow"):
        if editable:
          button(
            class =
              if isCursorShownStep and not self.simulator[].editData.step.pivot:
                SelectCellCls
              else:
                NotSelectCellCls,
            style = style(StyleAttr.maxHeight, "24px"),
            onclick = self.initWriteBtnHandler(stepIdx, false),
          ):
            figure(class = "image is-24x24"):
              img(src = rotorSrc)
        else:
          figure(class = "image is-24x24"):
            img(src = rotorSrc)
      # placement
      if not isPlaceholder:
        tdiv(class = "column is-narrow"):
          text optPlcmtDesc

  proc garbagesNode(
      self: StepsView, stepIdx: int, step: Step, editable: bool
  ): VNode {.inline.} =
    ## Returns the garbages node.
    let cellSrc = (if step.dropHard: Hard else: Garbage).cellImgSrc

    buildHtml tdiv(class = "columns is-mobile is-gapless"):
      # garbage/hard
      tdiv(class = "column is-narrow"):
        # TODO: handler
        if editable:
          button(class = NotSelectCellCls, style = style(StyleAttr.maxHeight, "16px")):
            figure(class = "image is-16x16"):
              img(src = cellSrc)
        else:
          figure(class = "image is-16x16"):
            img(src = cellSrc)
      # cnts
      tdiv(class = "column is-narrow"):
        table(class = "table"):
          tbody:
            tr:
              for col in Col:
                td:
                  if editable:
                    text $step.cnts[col] # TODO
                  else:
                    text $step.cnts[col]

  proc toVNode*(self: StepsView): VNode {.inline.} =
    ## Returns the steps view.
    let
      editable = self.simulator[].mode == EditorEdit and not self.displayMode
      steps = self.simulator[].nazoPuyoWrap.runIt:
        it.steps

    buildHtml table(class = "table is-narrow"):
      tbody:
        for stepIdx, step in steps:
          let rowCls =
            if editable and self.simulator[].state == Stable and
                self.simulator[].operatingIdx == stepIdx:
              "is-selected".cstring
            else:
              "".cstring

          tr(class = rowCls):
            # delete button
            if editable:
              td:
                button(
                  class = "button is-size-7",
                  onclick = self.initDeleteBtnHandler stepIdx,
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-trash")

            # index
            td:
              text $stepIdx.succ

            # step
            td:
              case step.kind
              of PairPlacement:
                self.pairPlcmtNode(stepIdx, editable)
              of StepKind.Garbages:
                self.garbagesNode(stepIdx, step, editable)

        # placeholder after the last step
        if editable:
          let placeholderIdx = steps.len

          tr:
            # hidden placeholder to align
            td:
              button(
                class = "button is-static",
                style = style(StyleAttr.visibility, "hidden"),
              ):
                span(class = "icon"):
                  italic(class = "fa-solid fa-trash")

            # index
            td:
              text $placeholderIdx.succ

            # empty step
            td:
              self.pairPlcmtNode(placeholderIdx, true)
