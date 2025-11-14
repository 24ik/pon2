## This module implements message views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import karax/[karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[arrayops2, assign3, gui, math2]

  export vdom

when defined(js) or defined(nimsuggest):
  const ShowNoticeGarbageCnt = 6

  proc txtMsg[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): string =
    ## Returns the text message.
    if self.derefSimulator(helper).nazoPuyoWrap.optGoal.isOk:
      $helper.simulator.markResultOpt.unsafeValue
    else:
      let nazoWrap = self.derefSimulator(helper).nazoPuyoWrap
      nazoWrap.unwrapNazoPuyo:
        if self.derefSimulator(helper).state == Stable and it.field.isDead:
          $MarkResult.Dead
        else:
          ""

  proc score[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): int =
    ## Returns the score.
    self.derefSimulator(helper).moveResult.score.unsafeValue

  proc noticeGarbageCnts[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, score: int
  ): array[NoticeGarbage, int] =
    ## Returns the numbers of notice garbages.
    let originalNoticeGarbageCnts =
      score.noticeGarbageCnts(self.derefSimulator(helper).rule).unsafeValue

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

  proc toMsgVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the message node.
    let
      score = self.score helper
      noticeGarbageCnts = self.noticeGarbageCnts(helper, score)

    buildHtml tdiv:
      if self.derefSimulator(helper).nazoPuyoWrap.optGoal.isErr:
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
      text self.txtMsg(helper).cstring
