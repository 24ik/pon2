{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[cell, moveresult, notice, rule]
import ../../src/pon2/private/[arrayops2]

let
  chainCnt = 3
  popCnts: array[Cell, int] = [0, 1, 12, 12, 4, 13, 0, 15]
  hardToGarbageCnt = 3
  detailHardToGarbageCnt = @[1, 2, 0]

  detailArr1: array[Cell, int] = [0, 1, 0, 4, 0, 5, 0, 9]
  detailArr2: array[Cell, int] = [0, 0, 0, 4, 4, 0, 0, 0]
  detailArr3: array[Cell, int] = [0, 0, 12, 4, 0, 8, 0, 6]
  detailPopCnts = @[detailArr1, detailArr2, detailArr3]

  fullArr1: array[Cell, seq[int]] = [@[], @[1], @[], @[4], @[], @[5], @[], @[4, 5]]
  fullArr2: array[Cell, seq[int]] = [@[], @[], @[], @[4], @[4], @[], @[], @[]]
  fullArr3: array[Cell, seq[int]] = [@[], @[], @[4, 4, 4], @[4], @[], @[5], @[], @[6]]
  fullPopCnts = @[fullArr1, fullArr2, fullArr3]

  moveRes1 = MoveResult.init(
    chainCnt, popCnts, hardToGarbageCnt, detailPopCnts, detailHardToGarbageCnt
  )
  moveRes2 = MoveResult.init(
    chainCnt, popCnts, hardToGarbageCnt, detailPopCnts, detailHardToGarbageCnt,
    fullPopCnts,
  )

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check moveRes1 ==
    MoveResult(
      chainCnt: chainCnt,
      popCnts: popCnts,
      hardToGarbageCnt: hardToGarbageCnt,
      detailPopCnts: detailPopCnts,
      detailHardToGarbageCnt: detailHardToGarbageCnt,
      fullPopCnts: Opt[seq[array[Cell, seq[int]]]].err,
    )
  check moveRes2 ==
    MoveResult(
      chainCnt: chainCnt,
      popCnts: popCnts,
      hardToGarbageCnt: hardToGarbageCnt,
      detailPopCnts: detailPopCnts,
      detailHardToGarbageCnt: detailHardToGarbageCnt,
      fullPopCnts: Opt[seq[array[Cell, seq[int]]]].ok fullPopCnts,
    )

  check MoveResult.init == MoveResult.init(0, initArrWith[Cell, int](0), 0, @[], @[])

# ------------------------------------------------
# Count
# ------------------------------------------------

block:
  # cellCnt, puyoCnt, colorPuyoCnt, garbagesCnt,
  # cellCnts, puyoCnts, colorPuyoCnts, garbagesCnts
  let
    cntP = 15
    cntY = 0
  check moveRes1.cellCnt(Purple) == cntP
  check moveRes2.cellCnt(Purple) == cntP
  check moveRes1.cellCnt(Yellow) == cntY
  check moveRes2.cellCnt(Yellow) == cntY

  let cntPuyo = 57
  check moveRes1.puyoCnt == cntPuyo
  check moveRes2.puyoCnt == cntPuyo

  let cntColor = 44
  check moveRes1.colorPuyoCnt == cntColor
  check moveRes2.colorPuyoCnt == cntColor

  let cntGarbages = 13
  check moveRes1.garbagesCnt == cntGarbages
  check moveRes2.garbagesCnt == cntGarbages

  let
    cntsB = @[5, 0, 8]
    cntsY = @[0, 0, 0]
  check moveRes1.cellCnts(Blue) == cntsB
  check moveRes2.cellCnts(Blue) == cntsB
  check moveRes1.cellCnts(Yellow) == cntsY
  check moveRes2.cellCnts(Yellow) == cntsY

  let cntsPuyo = @[19, 8, 30]
  check moveRes1.puyoCnts == cntsPuyo
  check moveRes2.puyoCnts == cntsPuyo

  let cntsColor = @[18, 8, 18]
  check moveRes1.colorPuyoCnts == cntsColor
  check moveRes2.colorPuyoCnts == cntsColor

  let cntsGarbages = @[1, 0, 12]
  check moveRes1.garbagesCnts == cntsGarbages
  check moveRes2.garbagesCnts == cntsGarbages

# ------------------------------------------------
# Color
# ------------------------------------------------

block: # colors, colorsSeq
  let colors2 = {Red, Green, Blue, Purple}
  check moveRes1.colors == colors2
  check moveRes2.colors == colors2

  let colorsSeq2 = @[{Red, Blue, Purple}, {Red, Green}, {Red, Blue, Purple}]
  check moveRes1.colorsSeq == colorsSeq2
  check moveRes2.colorsSeq == colorsSeq2

# ------------------------------------------------
# Place
# ------------------------------------------------

block: # placeCnts
  check moveRes1.placeCnts(Purple).isErr
  check moveRes2.placeCnts(Purple) == Res[seq[int]].ok @[2, 0, 1]
  check moveRes1.placeCnts(Yellow).isErr
  check moveRes2.placeCnts(Yellow) == Res[seq[int]].ok @[0, 0, 0]

  check moveRes1.placeCnts.isErr
  check moveRes2.placeCnts == Res[seq[int]].ok @[4, 2, 3]

# ------------------------------------------------
# Connect
# ------------------------------------------------

block: # connCnts
  check moveRes1.connCnts(Purple).isErr
  check moveRes2.connCnts(Purple) == Res[seq[int]].ok @[4, 5, 6]
  check moveRes1.connCnts(Yellow).isErr
  check moveRes2.connCnts(Yellow) == Res[seq[int]].ok @[]

  check moveRes1.connCnts.isErr
  check moveRes2.connCnts == Res[seq[int]].ok @[4, 5, 4, 5, 4, 4, 4, 5, 6]

# ------------------------------------------------
# Score
# ------------------------------------------------

let scoreAns = 8660

block: # score
  check moveRes1.score.isErr
  check moveRes2.score == Res[int].ok scoreAns

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

block: # noticeGarbageCnts
  check moveRes1.noticeGarbageCnts(Tsu).isErr
  check moveRes2.noticeGarbageCnts(Tsu) == scoreAns.noticeGarbageCnts Tsu

  check moveRes1.noticeGarbageCnts(Water).isErr
  check moveRes2.noticeGarbageCnts(Water) == scoreAns.noticeGarbageCnts Water
