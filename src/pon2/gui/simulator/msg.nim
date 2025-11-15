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
  import ../../private/[arrayutils, assign, gui, math]

  export vdom

when defined(js) or defined(nimsuggest):
  const ShowNoticeCount = 6

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

  proc noticeCounts[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper, score: int
  ): array[Notice, int] =
    ## Returns the numbers of notice garbages.
    let originalNoticeCounts = score.noticeCounts(self.derefSimulator(helper).rule)

    var
      counts = Notice.initArrayWith 0
      totalCount = 0
    for notice in countdown(Comet, Small):
      counts[notice].assign originalNoticeCounts[notice]
      totalCount.inc min(originalNoticeCounts[notice], ShowNoticeCount - totalCount)

      if totalCount >= ShowNoticeCount:
        break

    counts

  proc toMsgVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the message node.
    let
      score = self.score helper
      noticeCounts = self.noticeCounts(helper, score)

    buildHtml tdiv:
      if self.derefSimulator(helper).nazoPuyoWrap.optGoal.isErr:
        table:
          tbody:
            tr:
              for notice in countdown(Comet, Small):
                for _ in 1 .. noticeCounts[notice]:
                  td:
                    figure(class = "image is-16x16"):
                      img(src = notice.noticeImgSrc)

              for _ in 1 .. ShowNoticeCount - noticeCounts.sum:
                td:
                  figure(class = "image is-16x16"):
                    img(src = Cell.None.cellImgSrc)
              td:
                tdiv(class = "is-size-7"):
                  text $score
      text self.txtMsg(helper).cstring
