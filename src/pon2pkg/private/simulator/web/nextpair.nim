## This module implements the next pair node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[karaxdsl, vdom]
import ./[misc]
import ../[render]
import ../../../corepkg/[misc]
import ../../../simulatorpkg/[simulator]

proc nextPairNode*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the next pair node.
  buildHtml(table):
    tbody:
      for idx in -1..1:
        tr:
          for col in Column.low..Column.high:
            td:
              figure(class = "image is-24x24"):
                img(src = simulator.nextPairCell(idx, col).cellImageSrc)
