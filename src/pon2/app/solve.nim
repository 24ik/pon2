## This module implements Nazo Puyo solvers.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm]
import ../[core]
import ../private/[core, macros2, utils]
import ../private/app/[solve]

when defined(js) or defined(nimsuggest):
  import std/[dom]
  import ../private/[strutils2, webworker]

when not defined(js):
  import std/[os, sequtils, sugar]

  {.push warning[Deprecated]: off.}
  import std/[threadpool]
  {.pop.}

type SolveAnswer* = seq[OptPlacement]
  ## Nazo Puyo answer.
  ## Elements corresponding to non-`PairPlacement` steps are set to `NonePlacement`.

# ------------------------------------------------
# Static Getter
# ------------------------------------------------

template withStaticColor(goal: Goal, body: untyped): untyped =
  ## Runs `body` with `StaticColor` exposed.
  case goal.optColor.unsafeValue
  of All:
    const StaticColor {.inject.} = All
    body
  of GoalColor.Red:
    const StaticColor {.inject.} = GoalColor.Red
    body
  of GoalColor.Green:
    const StaticColor {.inject.} = GoalColor.Green
    body
  of GoalColor.Blue:
    const StaticColor {.inject.} = GoalColor.Blue
    body
  of GoalColor.Yellow:
    const StaticColor {.inject.} = GoalColor.Yellow
    body
  of GoalColor.Purple:
    const StaticColor {.inject.} = GoalColor.Purple
    body
  of GoalColor.Garbages:
    const StaticColor {.inject.} = GoalColor.Garbages
    body
  of Colors:
    const StaticColor {.inject.} = Colors
    body

template withStaticKindColor(goal: Goal, body: untyped): untyped =
  ## Runs `body` with `StaticKind` and `StaticColor` exposed.
  case goal.kind
  of Clear:
    const StaticKind {.inject.} = Clear
    goal.withStaticColor:
      body
  of AccColor:
    const
      StaticKind {.inject.} = AccColor
      StaticColor {.inject.} = GoalColor.low
    body
  of AccColorMore:
    const
      StaticKind {.inject.} = AccColorMore
      StaticColor {.inject.} = GoalColor.low
    body
  of AccCnt:
    const StaticKind {.inject.} = AccCnt
    goal.withStaticColor:
      body
  of AccCntMore:
    const StaticKind {.inject.} = AccCntMore
    goal.withStaticColor:
      body
  of Chain:
    const
      StaticKind {.inject.} = Chain
      StaticColor {.inject.} = GoalColor.low
    body
  of ChainMore:
    const
      StaticKind {.inject.} = ChainMore
      StaticColor {.inject.} = GoalColor.low
    body
  of ClearChain:
    const StaticKind {.inject.} = ClearChain
    goal.withStaticColor:
      body
  of ClearChainMore:
    const StaticKind {.inject.} = ClearChainMore
    goal.withStaticColor:
      body
  of Color:
    const
      StaticKind {.inject.} = Color
      StaticColor {.inject.} = GoalColor.low
    body
  of ColorMore:
    const
      StaticKind {.inject.} = ColorMore
      StaticColor {.inject.} = GoalColor.low
    body
  of Cnt:
    const StaticKind {.inject.} = Cnt
    goal.withStaticColor:
      body
  of CntMore:
    const StaticKind {.inject.} = CntMore
    goal.withStaticColor:
      body
  of Place:
    const StaticKind {.inject.} = Place
    goal.withStaticColor:
      body
  of PlaceMore:
    const StaticKind {.inject.} = PlaceMore
    goal.withStaticColor:
      body
  of Conn:
    const StaticKind {.inject.} = Conn
    goal.withStaticColor:
      body
  of ConnMore:
    const StaticKind {.inject.} = ConnMore
    goal.withStaticColor:
      body

# ------------------------------------------------
# Solve
# ------------------------------------------------

when not defined(js):
  proc solveSingleThread[F: TsuField or WaterField](
      self: SolveNode[F],
      answers: ptr seq[SolveAnswer],
      moveCnt: int,
      goal: Goal,
      steps: Steps,
      calcAllAnswers: static bool,
      kind: static GoalKind,
      color: static GoalColor,
  ): bool {.inline.} =
    ## Solves the Nazo Puyo at the node with a single thread.
    ## This function requires that the field is settled and `answers` is empty.
    ## `answers` is set in reverse order.
    ## `result` has no meanings; only used to get FlowVar.
    # NOTE: non-static arguments should be placed before static ones due to `spawn` bug.
    self.solveSingleThread(
      answers[], moveCnt, calcAllAnswers, goal, kind, color, steps, isZeroDepth = true
    )
    true

  func checkSpawnFinished(
      futures: seq[FlowVar[bool]],
      answers: var seq[SolveAnswer],
      answersSeq: var seq[seq[SolveAnswer]],
      runningNodeIndices: var set[int16],
      optPlcmtsSeq: seq[seq[OptPlacement]],
      calcAllAnswers: static bool,
  ) {.inline.} =
    ## Checks all the spawned threads and reflects results if they have finished.
    var finishNodeIndices = set[int16]({})

    for runningNodeIdx in runningNodeIndices:
      if not futures[runningNodeIdx].isReady:
        continue

      finishNodeIndices.incl runningNodeIdx

      let optPlcmts = optPlcmtsSeq[runningNodeIdx]
      for ans in answersSeq[runningNodeIdx].mitems:
        ans &= optPlcmts
        ans.reverse

      when not calcAllAnswers:
        if answers.len + answersSeq[runningNodeIdx].len > 1:
          answers &= answersSeq[runningNodeIdx]

          return

    runningNodeIndices.excl finishNodeIndices

  proc solveMultiThread[F: TsuField or WaterField](
      self: SolveNode[F],
      answers: var seq[SolveAnswer],
      moveCnt: int,
      calcAllAnswers: static bool,
      goal: Goal,
      kind: static GoalKind,
      color: static GoalColor,
      steps: Steps,
  ) {.inline.} =
    ## Solves the Nazo Puyo at the node with multiple threads.
    ## This function requires that the field is settled and `answers` is empty.
    const
      SpawnWaitMs = 25
      SolveWaitMs = 50

    var
      nodes = newSeq[SolveNode[F]]()
      optPlcmtsSeq = newSeq[seq[OptPlacement]]()
    self.childrenAtDepth nodes,
      optPlcmtsSeq, answers, moveCnt, calcAllAnswers, goal, kind, color, steps

    for ans in answers.mitems:
      ans.reverse

    when not calcAllAnswers:
      if answers.len > 1:
        return

    let nodeCnt = nodes.len
    var
      answersSeq = collect:
        for _ in 1 .. nodes.len:
          newSeq[SolveAnswer]()
      futures = newSeqOfCap[FlowVar[bool]](nodeCnt)
      runningNodeIndices = set[int16]({})

    var nodeIdx = 0'i16
    while nodeIdx < nodeCnt:
      if preferSpawn():
        futures.add spawn nodes[nodeIdx].solveSingleThread(
          answersSeq[nodeIdx].addr, moveCnt, goal, steps, calcAllAnswers, kind, color
        )

        runningNodeIndices.incl nodeIdx
        nodeIdx.inc

        continue

      futures.checkSpawnFinished answers,
        answersSeq, runningNodeIndices, optPlcmtsSeq, calcAllAnswers
      sleep SpawnWaitMs

    while runningNodeIndices.card > 0:
      futures.checkSpawnFinished answers,
        answersSeq, runningNodeIndices, optPlcmtsSeq, calcAllAnswers
      sleep SolveWaitMs

    answers &= answersSeq.concat

proc solve*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], calcAllAnswers: static bool = true
): seq[SolveAnswer] {.inline.} =
  ## Solves the Nazo Puyo.
  ## A single thread is used on JS backend; otherwise multiple threads are used.
  ## This function requires that the field is settled.
  if not nazo.goal.isSupported or nazo.puyoPuyo.steps.len == 0:
    return @[]

  let
    root = SolveNode[F].init nazo.puyoPuyo
    moveCnt = nazo.puyoPuyo.steps.len
  var answers = newSeq[SolveAnswer]()

  nazo.goal.withStaticKindColor:
    when defined(js):
      root.solveSingleThread(
        answers,
        moveCnt,
        calcAllAnswers,
        nazo.goal,
        StaticKind,
        StaticColor,
        nazo.puyoPuyo.steps,
        isZeroDepth = true,
      )

      for ans in answers.mitems:
        ans.reverse
    else:
      root.solveMultiThread(
        answers, moveCnt, calcAllAnswers, nazo.goal, StaticKind, StaticColor,
        nazo.puyoPuyo.steps,
      )

  answers

# ------------------------------------------------
# Solve - Async
# ------------------------------------------------

#[
when defined(js) or defined(nimsuggest):
  const
    Sep1 = "_"
    Sep2 = "~"
    Sep3 = ":"
    Sep4 = ";"
    Sep5 = "|"
    OkStr = "ok"
    ErrStr = "err"

  func toStr(self: MoveResult): string {.inline.} =
    ## Returns the string representation of the move result.
    var strs = newSeqOfCap[string](6)

    strs.add $self.chainCnt
    strs.add self.popCnts.mapIt($it).join Sep1
    strs.add $self.hardToGarbageCnt
    strs.add self.detailPopCnts.mapIt(it.map((cnt: int) => $cnt).join Sep1).join Sep2
    strs.add self.detailHardToGarbageCnt.mapIt($it).join Sep1
    if self.fullPopCnts.isOk:
      strs.add OkStr & Sep4 &
        self.fullPopCnts.unsafeValue.mapIt(
          it.map((cnts: seq[int]) => cnts.map((cnt: int) => $cnt).join Sep1).join Sep2
        ).join Sep3
    else:
      strs.add ErrStr

    strs.join Sep5

  func toStr(self: set[Cell]): string {.inline.} =
    ## Returns the string representation of the cells.
    self.mapIt($it).join

  func toStrs[F: TsuField or WaterField](self: SolveNode[F]): seq[string] {.inline.} =
    ## Returns the string representations of the node.
    var strs = newSeqOfCap[string](7)

    strs.add $self.depth

    strs.add $self.field.toUriQuery
    strs.add self.moveReult.toStr

    strs.add self.popColors.toStr
    strs.add $self.popCnt

    strs.add $self.fieldCnts.toStr
    strs.add $self.stepsCnts.toStr

    strs

  func toSolveAnswers(res: Res[seq[string]]): seq[SolveAnswer] {.inline.} =
    ## Returns the answers converted from the run result.
    if res.isErr:
      return @[]

    var answers = newSeqOfCap[SolveAnswer](res.unsafeValue.len)
    for str in res.unsafeValue:
      if str.len mod 2 == 1:
        continue

      var ans = newSeqOfCap[OptPlacement](str.len div 2)
      for charIdx in countup(0, str.len.pred, 2):
        let optPlcmtRes = str.substr(charIdx, charIdx.succ).parseOptPlacement
        if optPlcmtRes.isOk:
          ans.add optPlcmtRes.unsafeValue

      answers.add ans

    answers

  proc solveAsync*[F: TsuField or WaterField](
      nazo: NazoPuyo[F],
      progress: ref tuple[now: int, total: int],
      workerCnt: int,
      calcAllAnswers: static bool = true,
  ): Future[seq[SolveAnswer]] {.inline, async.} =
    ## Solves the Nazo Puyo asynchronously with web workers.
    ## This function requires that the field is settled.
    const WaitIntervalMs = 100

    await sleepZeroAsync()

    let root = SolveNode[F].init nazo.puyoPuyo

    var
      nodes = newSeq[SolveNode[F]]()
      optPlcmtsSeq = newSeq[seq[OptPlacement]]()
      answers = newSeq[SolveAnswer]()

    nazo.goal.withStaticKindColor:
      root.childrenAtDepth(
        nodes, optPlcmtsSeq, answers, nazo.puyoPuyo.steps.len, calcAllAnswers,
        nazo.goal, StaticKind, StaticColor, nazo.puyoPuyo.steps,
      )

    for ans in answers.mitems:
      ans.reverse

    when not calcAllAnswers:
      if answers.len > 1:
        return answers

    let nodeCnt = nodes.len
    progress[].now.assign 0
    progress[].total.assign nodeCnt

    var
      workers = collect:
        for _ in 1 .. workerCnt:
          WebWorker.init
      answersSeq = collect:
        for _ in 1 .. nodes.len:
          newSeq[SolveAnswer]()
      runningWorkerIndices = set[int16]({})
      nodeIdx = 0'i16

    proc runWorker(workerIdx: int16) =
      if nodeIdx >= nodeCnt:
        return

      runningWorkerIndices.incl workerIdx
      let nowNodeIdx = nodeIdx
      nodeIdx.inc

      discard workers[workerIdx].run(nodes[nowNodeIdx].toStrs).then(
          (res: Res[seq[string]]) => (
            block:
              progress[].now.inc
              answersSeq[nowNodeIdx].assign res.toSolveAnswers
              runningWorkerIndices.excl workerIdx

              workerIdx.runWorker
          )
        )

    let workerIndices = 0'i16 ..< workerCnt.int16
    for workerIdx in workerIndices:
      workerIdx.runTask

    while runningWorkerIndices.card > 0:
      var finishWorkerIndices = set[int16]({})

      for workerIdx in runningWorkerIndices:
        if workers[workerIdx].isRunning:
          continue

        finishWorkerIndices.incl workerIdx

      runningWorkerIndices.excl finishWorkerIndices

      await sleepAsync WaitIntervalMs

    answers &= answersSeq.concat

    answers
]#
