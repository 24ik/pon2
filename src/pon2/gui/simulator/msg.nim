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

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  const ShowNoticeCount = 6

  proc txtMsg[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): string =
    ## Returns the text message.
    if self.derefSimulator(helper).nazoPuyo.goal == NoneGoal:
      if self.derefSimulator(helper).state == Stable and
          self.derefSimulator(helper).nazoPuyo.puyoPuyo.field.isDead:
        $MarkResult.Dead
      else:
        ""
    else:
      $helper.simulator.markResult

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
      let count = min(originalNoticeCounts[notice], ShowNoticeCount - totalCount)
      counts[notice].assign count
      totalCount.inc count

    counts

  proc toMsgVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the message node.
    let
      score = self.score helper
      noticeCounts = self.noticeCounts(helper, score)
      showNotice = self.derefSimulator(helper).nazoPuyo.goal == NoneGoal

    buildHtml tdiv:
      if showNotice:
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
                  text (" " & $score).kstring
      text self.txtMsg(helper).kstring
