## This module implements operating views.
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

  proc toOperatingCellVNode[S: Simulator or Studio or Marathon or Grimoire](
      self: ref S, helper: VNodeHelper, index: int, col: Col
  ): VNode =
    ## Returns the node of the cell in the operating area.
    var cross = false
    let cellOpt =
      if self.derefSimulator(helper).state != Stable or
          self.derefSimulator(helper).mode notin PlayModes:
        Opt[Cell].ok Cell.None
      else:
        if self.derefSimulator(helper).operating.index >=
            self.derefSimulator(helper).nazoPuyo.puyoPuyo.steps.len:
          Opt[Cell].ok Cell.None
        else:
          let step = self.derefSimulator(helper).nazoPuyo.puyoPuyo.steps[
            self.derefSimulator(helper).operating.index
          ]
          case step.kind
          of PairPlace:
            # pivot
            if index == 1 and
                col == self.derefSimulator(helper).operating.placement.pivotCol:
              Opt[Cell].ok step.pair.pivot
            # rotor
            elif col == self.derefSimulator(helper).operating.placement.rotorCol:
              if index == 1:
                Opt[Cell].ok step.pair.rotor
              elif index == 0 and
                  self.derefSimulator(helper).operating.placement.rotorDir == Up:
                Opt[Cell].ok step.pair.rotor
              elif index == 2 and
                  self.derefSimulator(helper).operating.placement.rotorDir == Down:
                Opt[Cell].ok step.pair.rotor
              else:
                Opt[Cell].ok Cell.None
            else:
              Opt[Cell].ok Cell.None
          of NuisanceDrop:
            if index == 2 and step.counts[col] > 0:
              Opt[Cell].ok (if step.hard: Hard else: Garbage)
            else:
              Opt[Cell].ok Cell.None
          of FieldRotate:
            cross = step.cross

            if index == 2 and col == Col2:
              Opt[Cell].err
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

  proc toOperatingVNode*[S: Simulator or Studio or Marathon or Grimoire](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the operating node.
    buildHtml table:
      tbody:
        for index in 0 ..< 3:
          tr:
            for col in Col:
              td:
                self.toOperatingCellVNode(helper, index, col)
