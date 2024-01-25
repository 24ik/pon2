## This module implements the immediate pairs node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[karaxdsl, vdom]
import ../[render]
import ../../[misc]
import ../../../../apppkg/[simulator]
import ../../../../corepkg/[cell]

proc initImmediatePairsNode*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the immediate pairs node.
  buildHtml(table):
    tbody:
      # indent
      for _ in 1..4:
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = cellImageSrc(None))

      # next-puyo
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = simulator.immediateNextPairCell(false).cellImageSrc)
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = simulator.immediateNextPairCell(true).cellImageSrc)

      # separator
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = None.cellImageSrc)

      # double-next-puyo
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = simulator.immediateDoubleNextPairCell(false).cellImageSrc)
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = simulator.immediateDoubleNextPairCell(true).cellImageSrc)
