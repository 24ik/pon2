## This module implements the next pair frame.
##

{.experimental: "strictDefs".}

import karax/[karaxdsl, vdom]
import ./[misc]
import ../[render, simulator]
import ../../core/[misc]

proc nextPairFrame*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the next pair frame.
  buildHtml(table):
    tbody:
      for idx in -1..1:
        tr:
          for col in Column.low..Column.high:
            td:
              figure(class = "image is-24x24"):
                img(src = simulator.nextPairCell(idx, col).cellImageSrc)
