## This module implements nexts views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import karax/[karaxdsl, vdom, vstyles]
  import ../[helper]
  import ../../[app]
  import ../../private/[gui]

  export vdom

  proc toNextCellVNode[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, doubleNext: bool, pivot: bool
  ): VNode =
    ## Returns the node of the cell in the next or double-next step.
    let stepIndex = self.derefSimulator(helper).operatingIndex.succ 1 + doubleNext.int

    var cross = false
    let cellOpt =
      if stepIndex < self.derefSimulator(helper).nazoPuyo.puyoPuyo.steps.len:
        let step = self.derefSimulator(helper).nazoPuyo.puyoPuyo.steps[stepIndex]
        case step.kind
        of PairPlace:
          Opt[Cell].ok if pivot: step.pair.pivot else: step.pair.rotor
        of GarbageDrop:
          Opt[Cell].ok if step.hard: Hard else: Garbage
        of FieldRotate:
          cross = step.cross

          if pivot:
            Opt[Cell].err
          else:
            Opt[Cell].ok Cell.None
      else:
        Opt[Cell].ok Cell.None

    buildHtml figure(class = "image is-24x24"):
      if cellOpt.isOk:
        img(src = cellOpt.unsafeValue.cellImgSrc)
      else:
        span(class = "icon"):
          if cross:
            span(class = "fa-stack", style = style(StyleAttr.fontSize, "0.5em")):
              italic(class = "fa-solid fa-arrows-rotate fa-stack-2x")
              italic(class = "fa-solid fa-c fa-stack-1x")
          else:
            italic(class = "fa-solid fa-arrows-rotate")

  proc toNextVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the next node.
    buildHtml table:
      tbody:
        # indent
        for _ in 1 .. 4:
          tr:
            td:
              figure(class = "image is-24x24"):
                img(src = Cell.None.cellImgSrc)

        # next
        tr:
          td:
            self.toNextCellVNode(helper, doubleNext = false, pivot = false)
        tr:
          td:
            self.toNextCellVNode(helper, doubleNext = false, pivot = true)

        # separator
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = Cell.None.cellImgSrc)

        # double next
        tr:
          td:
            self.toNextCellVNode(helper, doubleNext = true, pivot = false)
        tr:
          td:
            self.toNextCellVNode(helper, doubleNext = true, pivot = true)
