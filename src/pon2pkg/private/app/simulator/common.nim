## This module implements helper functions for the simulator.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, uri]
import ../../[misc]
import ../../../app/[color, nazopuyo, simulator]
import
  ../../../core/[
    cell, field, fieldtype, mark, moveresult, nazopuyo, notice, pair, pairposition,
    position, puyopuyo, rule,
  ]

when defined(js):
  import ../[misc]

# ------------------------------------------------
# Field
# ------------------------------------------------

proc fieldCellBackgroundColor*(
    simulator: Simulator, row: Row, col: Column, displayMode = false
): Color {.inline.} =
  ## Returns the cell's background color in the field.
  let hideCursor =
    when defined(js):
      isMobile()
    else:
      false

  result =
    if (
      not hideCursor and not displayMode and simulator.mode == Edit and
      simulator.editing.focusField and (row, col) == simulator.editing.field
    ):
      SelectColor
    elif row == Row.low:
      GhostColor
    elif simulator.rule == Water and row in WaterRow.low .. WaterRow.high:
      WaterColor
    else:
      DefaultColor

# ------------------------------------------------
# Pairs
# ------------------------------------------------

func needPairPointer*(simulator: Simulator, idx: Natural): bool {.inline.} =
  ## Returns `true` if it is need to show the pointer to the pair.
  simulator.mode != Edit and simulator.state == Stable and simulator.next.index == idx

proc pairCellBackgroundColor*(
    simulator: Simulator, idx: Natural, axis: bool
): Color {.inline.} =
  ## Returns the cell's background color in the pairs.
  let hideCursor =
    when defined(js):
      isMobile()
    else:
      false

  result =
    if (
      not hideCursor and simulator.mode == Edit and not simulator.editing.focusField and
      (idx, axis) == simulator.editing.pair
    ): SelectColor else: DefaultColor

# ------------------------------------------------
# Next Pair
# ------------------------------------------------

func nextPairCell*(
    simulator: Simulator, idx: range[-1 .. 1], col: Column
): Cell {.inline.} =
  ## Returns the cell in the next pairs.
  let
    pos = simulator.next.position
    noPosLeft: bool
    nextPair: Pair
  simulator.nazoPuyoWrap.get:
    noPosLeft = wrappedNazoPuyo.puyoPuyo.movingCompleted
    nextPair =
      if noPosLeft: Pair.low else: wrappedNazoPuyo.puyoPuyo.nextPairPosition.pair

  result =
    if simulator.state != Stable:
      Cell.None
    elif noPosLeft:
      Cell.None
    elif idx == 0 and col == pos.axisColumn:
      nextPair.axis
    elif (
      # Up, Down
      (
        col == pos.axisColumn and (
          (idx == -1 and pos.childDirection == Up) or
          (idx == 1 and pos.childDirection == Down)
        )
      ) or
      # Right, Left
      (
        idx == 0 and (
          (col == pos.axisColumn.succ and pos.childDirection == Right) or
          (col == pos.axisColumn.pred and pos.childDirection == Left)
        )
      )
    ):
      nextPair.child
    else:
      Cell.None

# ------------------------------------------------
# Immediate Pairs
# ------------------------------------------------

func immediateNextPairCell*(simulator: Simulator, axis: bool): Cell {.inline.} =
  ## Returns the next-pair's cell in the immediate pairs.
  simulator.nazoPuyoWrap.get:
    let nextIdx = wrappedNazoPuyo.puyoPuyo.nextIndex
    if nextIdx >= wrappedNazoPuyo.puyoPuyo.pairsPositions.len:
      return Cell.None

    let pair = wrappedNazoPuyo.puyoPuyo.pairsPositions[nextIdx].pair
    result = if axis: pair.axis else: pair.child

func immediateDoubleNextPairCell*(simulator: Simulator, axis: bool): Cell {.inline.} =
  ## Returns the double-next-pair's cell in the immediate pairs.
  simulator.nazoPuyoWrap.get:
    let doubleNextIdx = wrappedNazoPuyo.puyoPuyo.nextIndex.succ
    if doubleNextIdx >= wrappedNazoPuyo.puyoPuyo.pairsPositions.len:
      return Cell.None

    let pair = wrappedNazoPuyo.puyoPuyo.pairsPositions[doubleNextIdx].pair
    result = if axis: pair.axis else: pair.child

# ------------------------------------------------
# Message
# ------------------------------------------------

const
  DeadMessage = "ばたんきゅ〜"
  NazoMessages: array[MarkResult, string] = [
    "クリア！", "　", DeadMessage, "不可能な設置", "設置スキップ",
    "未対応",
  ]
  ShownNoticeGarbgeCount = 6

func getMessages*(
    simulator: Simulator
): tuple[state: string, score: int, noticeGarbages: array[NoticeGarbage, int]] {.
    inline
.} =
  ## Returns the messages.
  ## Note that `noticeGarbages` in the result should be used only in rendering.
  if simulator.state == Stable:
    case simulator.kind
    of Regular:
      simulator.nazoPuyoWrap.get:
        result.state = if wrappedNazoPuyo.puyoPuyo.field.isDead: DeadMessage else: ""
    of Nazo:
      let
        pairsPositions: PairsPositions
        endIdx: Natural
      simulator.nazoPuyoWrap.get:
        pairsPositions = wrappedNazoPuyo.puyoPuyo.pairsPositions
        endIdx = wrappedNazoPuyo.puyoPuyo.nextIndex

      simulator.originalNazoPuyoWrap.get:
        var nazo = wrappedNazoPuyo
        nazo.puyoPuyo.pairsPositions = pairsPositions
        result.state = NazoMessages[nazo.mark endIdx]
  else:
    result.state = "　"

  result.score = simulator.score

  result.noticeGarbages = [0, 0, 0, 0, 0, 0, 0]
  let originalNoticeGarbages = result.score.noticeGarbageCounts simulator.rule
  var count = 0
  for notice in countdown(Comet, Small):
    result.noticeGarbages[notice] = originalNoticeGarbages[notice]
    count.inc originalNoticeGarbages[notice]
    if count > ShownNoticeGarbgeCount:
      result.noticeGarbages[notice].dec count - ShownNoticeGarbgeCount
    if count >= ShownNoticeGarbgeCount:
      break

# ------------------------------------------------
# X
# ------------------------------------------------

const RuleDescriptions: array[Rule, string] = ["通", "すいちゅう"]

func toXLink*(simulator: Simulator, withPositions: bool, editor: bool): Uri {.inline.} =
  ## Returns the URI for posting to X.
  let simulatorUri = simulator.toUri(withPositions, editor)

  if simulator.kind == Nazo:
    simulator.nazoPuyoWrap.get:
      let
        ruleStr = RuleDescriptions[simulator.rule]
        moveCount = wrappedNazoPuyo.moveCount
        reqStr = $wrappedNazoPuyo.requirement

      result = initXLink(
        &"{ruleStr}・{moveCount}手・{reqStr}", "なぞぷよ", simulatorUri
      )
  else:
    result = initXLink(uri = simulatorUri)
