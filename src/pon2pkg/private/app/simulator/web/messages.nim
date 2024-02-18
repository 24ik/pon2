## This module implements the messages node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[karaxdsl, vdom]
import ../[common]
import ../../[misc]
import ../../../../app/[simulator]
import ../../../../core/[notice]

proc initMessagesNode*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the messages node.
  let (state, score, noticeGarbages) = simulator.getMessages

  result = buildHtml(tdiv):
    if simulator.kind == Regular:
      table:
        tbody:
          tr:
            for notice in countdown(Comet, Small):
              let imgSrc = notice.noticeGarbageImageSrc

              for _ in 1 .. noticeGarbages[notice]:
                td:
                  figure(class = "image is-16x16"):
                    img(src = imgSrc)
            td:
              tdiv(class = "is-size-7"):
                text if score == 0:
                  "　"
                else:
                  $score
    text state
