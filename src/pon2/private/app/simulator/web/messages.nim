## This module implements the messages node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[karaxdsl, vdom]
import ../[common]
import ../../[misc]
import ../../../[misc]
import ../../../../app/[simulator]
import ../../../../core/[notice]

proc initMessagesNode*(simulator: ref Simulator): VNode {.inline.} =
  ## Returns the messages node.
  let
    (state, score, noticeGarbages) = simulator[].getMessages
    noneNoticeGarbageCount = ShownNoticeGarbageCount - noticeGarbages.sum2

  result = buildHtml(tdiv):
    if simulator[].kind == Regular:
      table:
        tbody:
          tr:
            for notice in countdown(Comet, Small):
              let
                imgSrc = notice.noticeGarbageImageSrc
                count = noticeGarbages[notice]

              for _ in 1 .. count:
                td:
                  figure(class = "image is-16x16"):
                    img(src = imgSrc)

            for _ in 1 .. noneNoticeGarbageCount:
              td:
                figure(class = "image is-16x16"):
                  img(src = NoticeGarbageNoneImageSrc)
            td:
              tdiv(class = "is-size-7"):
                text if score == 0:
                  "　"
                else:
                  $score
    else:
      text "　"
    text state
