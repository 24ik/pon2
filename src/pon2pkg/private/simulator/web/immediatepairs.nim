## This module implements the immediate pairs frame.
##

{.experimental: "strictDefs".}

import karax/[karaxdsl, vdom]
import ./[misc]
import ../[render]
import ../../../corepkg/[cell]
import ../../../simulatorpkg/[simulator]

proc immediatePairsFrame*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the immediate pairs frame.
  buildHtml(table):
    tbody:
      # indent
      for _ in 0..<4:
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = cellImageSrc(Cell.None))

      # next-puyo
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = cellImageSrc(simulator.immediateNextPairCell false))
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = cellImageSrc(simulator.immediateNextPairCell true))

      # separator
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = cellImageSrc(Cell.None))

      # double-next-puyo
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = cellImageSrc(simulator.immediateDoubleNextPairCell false))
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = cellImageSrc(simulator.immediateDoubleNextPairCell true))
