## This module implements message views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import karax/[karaxdsl, vdom]
  import ../[nazopuyowrap, simulator]
  import ../../[core]
  import ../../private/[arrayops2, assign3, math2]
  import ../../private/app/simulator/[common]

type MsgView* = object ## View of the message.
  simulator: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type MsgView, simulator: ref Simulator): T {.inline.} =
  T(simulator: simulator)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

# TODO: better impl (draw only non-none notice garbages)
# TODO: better message (nazo)
when defined(js) or defined(nimsuggest):
  const ShowNoticeGarbageCnt = 6

  func msg(self: MsgView): string {.inline.} =
    ## Returns the message.
    if self.simulator[].state != Stable:
      return ""

    if self.simulator[].nazoPuyoWrap.optGoal.isOk:
      self.simulator[].nazoPuyoWrap.runIt:
        $itNazo.mark self.simulator[].operatingIdx
    else:
      self.simulator[].nazoPuyoWrap.runIt:
        if it.field.isDead:
          $MarkResult.Dead
        else:
          ""

  func score(self: MsgView): int {.inline.} =
    ## Returns the score.
    self.simulator[].moveResult.score.unsafeValue

  func noticeGarbageCnts(
      self: MsgView, score: int
  ): array[NoticeGarbage, int] {.inline.} =
    ## Returns the numbers of notice garbages.
    let originalNoticeGarbageCnts =
      score.noticeGarbageCnts(self.simulator[].rule).unsafeValue

    var
      cnts = initArrWith[NoticeGarbage, int](0)
      totalCnt = 0
    for notice in countdown(Comet, Small):
      cnts[notice].assign originalNoticeGarbageCnts[notice]
      totalCnt.inc min(
        originalNoticeGarbageCnts[notice], ShowNoticeGarbageCnt - totalCnt
      )

      if totalCnt >= ShowNoticeGarbageCnt:
        break

    cnts

  proc toVNode*(self: MsgView): VNode {.inline.} =
    ## Returns the message node.
    let
      score = self.score
      noticeGarbageCnts = self.noticeGarbageCnts score

    buildHtml tdiv:
      table:
        tbody:
          tr:
            for notice in countdown(Comet, Small):
              for _ in 1 .. noticeGarbageCnts[notice]:
                td:
                  figure(class = "image is-16x16"):
                    img(src = notice.noticeGarbageImgSrc)

            for _ in 1 .. ShowNoticeGarbageCnt - noticeGarbageCnts.sum2:
              td:
                figure(class = "image is-16x16"):
                  img(src = Cell.None.cellImgSrc)
            td:
              tdiv(class = "is-size-7"):
                text $score
      text self.msg
