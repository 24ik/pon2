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
  import ../../private/[arrayutils, assign3, gui, math2]

  export vdom

when defined(js) or defined(nimsuggest):
  const ShowNoticeCnt = 6

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

  proc noticeCnts[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, score: int
  ): array[Notice, int] =
    ## Returns the numbers of notice garbages.
    let originalNoticeCnts = score.noticeCnts(self.derefSimulator(helper).rule)

    var
      cnts = Notice.initArrayWith 0
      totalCnt = 0
    for notice in countdown(Comet, Small):
      cnts[notice].assign originalNoticeCnts[notice]
      totalCnt.inc min(originalNoticeCnts[notice], ShowNoticeCnt - totalCnt)

      if totalCnt >= ShowNoticeCnt:
        break

    cnts

  proc toMsgVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the message node.
    let
      score = self.score helper
      noticeCnts = self.noticeCnts(helper, score)

    buildHtml tdiv:
      if self.derefSimulator(helper).nazoPuyoWrap.optGoal.isErr:
        table:
          tbody:
            tr:
              for notice in countdown(Comet, Small):
                for _ in 1 .. noticeCnts[notice]:
                  td:
                    figure(class = "image is-16x16"):
                      img(src = notice.noticeImgSrc)

              for _ in 1 .. ShowNoticeCnt - noticeCnts.sum2:
                td:
                  figure(class = "image is-16x16"):
                    img(src = Cell.None.cellImgSrc)
              td:
                tdiv(class = "is-size-7"):
                  text $score
      text self.txtMsg(helper).cstring
