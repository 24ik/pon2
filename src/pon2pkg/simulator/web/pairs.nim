## This module implements the pairs frame.
##

{.experimental: "strictDefs".}

import std/[options, sugar]
import karax/[karax, karaxdsl, kbase, vdom, vstyles]
import ./[misc]
import ../[simulator]
import ../../core/[cell, misc, pair]
import ../../private/simulator/[render]

func initDeleteClickHandler(simulator: var Simulator, idx: Natural):
    () -> void =
  ## Returns the click handler for delete buttons.
  # NOTE: inline handler does not work due to specifications
  () => simulator.deletePair(idx)

func initCellClickHandler(simulator: var Simulator, idx: Natural,
                          isAxis: bool): () -> void =
  ## Returns the click handler for cell buttons.
  # NOTE: inline handler does not work due to specifications
  () => simulator.writeCell(idx, isAxis)

func cellClass(simulator: Simulator, idx: Natural, isAxis: bool): kstring
              {.inline.} =
  ## Returns the cell's class.
  if simulator.pairCellSelected(idx, isAxis):
    kstring"button p-0 is-selected is-primary"
  else:
    kstring"button p-0"

proc pairsFrame*(simulator: var Simulator, simple = false, showPosition = true):
    VNode {.inline.} =
  ## Returns the pairs frame.
  let showEditor = not simple and simulator.mode == IzumiyaSimulatorMode.Edit

  result = buildHtml(table(class = "table is-narrow")):
    tbody:
      for idx, pair in simulator.originalPairs:
        tr(class =
            if simulator.pairSelected(idx, simple): kstring"is-selected"
            else: kstring""):
          # delete button
          if showEditor:
            td:
              button(class = "button is-size-7",
                     onclick = simulator.initDeleteClickHandler(idx)):
                span(class = "icon"):
                  italic(class = "fa-solid fa-trash")

          # index
          td:
            text $idx.succ

          # pair
          td:
            tdiv(class = "columns is-mobile is-gapless"):
              tdiv(class = "column is-narrow"):
                if showEditor:
                  button(
                    class = simulator.cellClass(idx, true),
                    style = style(StyleAttr.maxHeight, kstring"24px"),
                    onclick = simulator.initCellClickHandler(idx, true),
                  ):
                    figure(class = "image is-24x24"):
                      img(src = cellImageSrc(pair.axis))
                else:
                  figure(class = "image is-24x24"):
                    img(src = cellImageSrc(pair.axis))
              tdiv(class = "column is-narrow"):
                if showEditor:
                  button(
                    class = simulator.cellClass(idx, false),
                    style = style(StyleAttr.maxHeight, kstring"24px"),
                    onclick = simulator.initCellClickHandler(idx, false),
                  ):
                    figure(class = "image is-24x24"):
                      img(src = cellImageSrc(pair.child))
                else:
                  figure(class = "image is-24x24"):
                    img(src = cellImageSrc(pair.child))

          # position
          if showPosition:
            let pos = simulator.positions[idx]
            td:
              text if pos.isSome: $pos.get else: ""
      # next pair for edit mode
      if showEditor:
        tr:
          td:
            button(class = "button is-static",
                   style = style(StyleAttr.visibility, kstring"hidden")):
              span(class = "icon"):
                italic(class = "fa-solid fa-trash")
          td:
            text $simulator.pairs.len.succ
          td:
            tdiv(class = "columns is-mobile is-gapless"):
              tdiv(class = "column is-narrow"):
                button(
                    class = simulator.cellClass(
                      simulator.pairs.len, true),
                    style = style(StyleAttr.maxHeight, kstring"24px"),
                    onclick = simulator.initCellClickHandler(
                      simulator.pairs.len, true)):
                  figure(class = "image is-24x24"):
                    img(src = cellImageSrc(Cell.None))
              tdiv(class = "column is-narrow"):
                button(
                    class = simulator.cellClass(
                      simulator.pairs.len, false),
                    style = style(StyleAttr.maxHeight, kstring"24px"),
                    onclick = simulator.initCellClickHandler(
                      simulator.pairs.len, false)):
                  figure(class = "image is-24x24"):
                    img(src = cellImageSrc(Cell.None))
