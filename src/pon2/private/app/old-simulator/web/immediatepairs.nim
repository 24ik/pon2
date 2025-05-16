## This module implements the immediate pairs node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[karaxdsl, vdom]
import ../[common]
import ../../[misc]
import ../../../../app/[simulator]
import ../../../../core/[cell]

proc newImmediatePairsNode*(simulator: Simulator): VNode {.inline.} =
  ## Returns the immediate pairs node.
  buildHtml(table):
    tbody:
      # indent
      for _ in 1 .. 4:
        tr:
          td:
            figure(class = "image is-24x24"):
              img(src = Cell.None.cellImageSrc)

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
            img(src = Cell.None.cellImageSrc)

      # double-next-puyo
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = simulator.immediateDoubleNextPairCell(false).cellImageSrc)
      tr:
        td:
          figure(class = "image is-24x24"):
            img(src = simulator.immediateDoubleNextPairCell(true).cellImageSrc)
