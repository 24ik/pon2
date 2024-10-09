## This module implements the operating node.
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
import ../../../../core/[fieldtype]

proc newOperatingNode*(simulator: ref Simulator): VNode {.inline.} =
  ## Returns the operating node.
  buildHtml(table):
    tbody:
      for idx in -1 .. 1:
        tr:
          for col in Column.low .. Column.high:
            td:
              figure(class = "image is-24x24"):
                img(src = simulator[].operatingPairCell(idx, col).cellImageSrc)
