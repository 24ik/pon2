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
  import std/[sequtils]
  import karax/[karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[arrayutils, assign, gui, math, strutils]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  const ShowNoticeCount = 6

  func noticeCounts[S: Simulator or Studio or Marathon or Grimoire](
      self: ref S, helper: VNodeHelper, score: int
  ): array[Notice, int] =
    ## Returns the numbers of notice garbages.
    let
      rule = self.derefSimulator(helper).rule
      originalNoticeCounts =
        score.noticeCounts(Behaviours[rule].garbageRate, useComet = rule != Rule.Tsu)

    var
      counts = Notice.initArrayWith 0
      totalCount = 0
    for notice in countdown(Comet, Small):
      let count = min(originalNoticeCounts[notice], ShowNoticeCount - totalCount)
      counts[notice].assign count
      totalCount += count

    counts

  func goalMsg[S: Simulator or Studio or Marathon or Grimoire](
      self: ref S, helper: VNodeHelper, goal: Goal
  ): string =
    ## Returns the goal message.
    let
      mainMsg =
        if goal.mainOpt.isOk:
          let
            main = goal.mainOpt.unsafeValue
            moveResult = self.derefSimulator(helper).moveResult

          case main.kind
          of Chain:
            "{moveResult.chainCount}連鎖".fmt
          of GoalKind.Color:
            let colorCount =
              if moveResult.chainCount == 0:
                0
              else:
                moveResult.colorsSeq[^1].card
            "{colorCount}色".fmt
          of Count:
            let count =
              if moveResult.chainCount == 0:
                0
              else:
                case main.color
                of All:
                  moveResult.puyoCounts[^1]
                of Nuisance:
                  moveResult.nuisancePuyoCounts[^1]
                of Colored:
                  moveResult.coloredPuyoCounts[^1]
                else:
                  moveResult.cellCounts(main.color.ord.Cell)[^1]
            "{count}個".fmt
          of Place:
            let placeCount =
              if moveResult.chainCount == 0:
                0
              else:
                case main.color
                of All, Nuisance, Colored:
                  moveResult.placeCounts.unsafeValue[^1]
                else:
                  moveResult.placeCounts(main.color.ord.Cell).unsafeValue[^1]
            "{placeCount}箇所".fmt
          of Connection:
            let connectionCount =
              if moveResult.chainCount == 0:
                0
              else:
                case main.color
                of All, Nuisance, Colored:
                  moveResult.fullPopCountsOpt.unsafeValue[^1].concat.max
                else:
                  moveResult.fullPopCountsOpt.unsafeValue[^1][main.color.ord.Cell].max
            "{connectionCount}箇所".fmt
          of AccumColor:
            let colorCount = ColoredPuyos.countIt moveResult.popCounts[it] > 0
            "{colorCount}色".fmt
          of AccumCount:
            let count =
              case main.color
              of All:
                moveResult.puyoCount
              of Nuisance:
                moveResult.nuisancePuyoCount
              of Colored:
                moveResult.coloredPuyoCount
              else:
                moveResult.cellCount main.color.ord.Cell
            "{count}個".fmt
        else:
          ""
      clearColorMsg =
        if goal.clearColorOpt.isOk:
          let
            clearColor = goal.clearColorOpt.unsafeValue
            count =
              case clearColor
              of All:
                self.derefSimulator(helper).nazoPuyo.puyoPuyo.field.puyoCount
              of Nuisance:
                self.derefSimulator(helper).nazoPuyo.puyoPuyo.field.nuisancePuyoCount
              of Colored:
                self.derefSimulator(helper).nazoPuyo.puyoPuyo.field.coloredPuyoCount
              else:
                self.derefSimulator(helper).nazoPuyo.puyoPuyo.field.cellCount clearColor.ord.Cell

          "残り{count}個".fmt
        else:
          ""

    "{mainMsg}&{clearColorMsg}".fmt.strip(chars = {'&'})

  proc toMsgVNode*[S: Simulator or Studio or Marathon or Grimoire](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the message node.
    let
      score = self.derefSimulator(helper).moveResult.score.unsafeValue
      noticeCounts = self.noticeCounts(helper, score)
      goal = self.derefSimulator(helper).nazoPuyo.goal

    buildHtml tdiv:
      if goal == NoneGoal or not goal.isSupported:
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
                  text " {score}".fmt.kstring
        if self.derefSimulator(helper).state == Stable and
            self.derefSimulator(helper).nazoPuyo.puyoPuyo.field.isDead:
          tdiv(class = "is-size-7"):
            text ($Dead).kstring
      else:
        p:
          text self.goalMsg(helper, goal).kstring
        p:
          text ($helper.simulator.markResult).kstring
