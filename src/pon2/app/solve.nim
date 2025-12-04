## This module implements Nazo Puyo solvers.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../[core]
import ../private/[algorithm, core]
import ../private/app/[solve]

export core

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    import std/[asyncjs, jsconsole, sequtils, sugar]
    import ../private/[assign, webworkers]

    export asyncjs

when not defined(js):
  import std/[os, sequtils, sugar]

  {.push warning[Deprecated]: off.}
  import std/[threadpool]
  {.pop.}

type SolveAnswer* = seq[OptPlacement]
  ## Nazo Puyo answer.
  ## Elements corresponding to non-`PairPlacement` steps are set to `NonePlacement`.

when not defined(js):
  proc solveSingleThread(
      self: SolveNode,
      answers: ptr seq[SolveAnswer],
      moveCount: int,
      calcAllAnswers: bool,
      goal: Goal,
      steps: Steps,
  ): bool =
    ## Solves the Nazo Puyo at the node with a single thread.
    ## This function requires that the field is settled and `answers` is empty.
    ## `answers` is set in reverse order.
    ## `result` has no meanings; only used to get FlowVar.
    self.solveSingleThread(
      answers[], moveCount, calcAllAnswers, goal, steps, checkPruneFirst = false
    )
    true

  func checkSpawnFinished(
      futures: seq[FlowVar[bool]],
      answers: var seq[SolveAnswer],
      answersSeq: var seq[seq[SolveAnswer]],
      runningNodeIndices: var set[int16],
      optPlacementsSeq: seq[seq[OptPlacement]],
      calcAllAnswers: bool,
  ): bool =
    ## Checks all the spawned threads and reflects results if they have finished.
    ## Returns `true` if early-returned.
    var finishNodeIndices = set[int16]({})

    for runningNodeIndex in runningNodeIndices:
      if not futures[runningNodeIndex].isReady:
        continue

      finishNodeIndices.incl runningNodeIndex

      let optPlacements = optPlacementsSeq[runningNodeIndex]
      for answer in answersSeq[runningNodeIndex].mitems:
        answer &= optPlacements
        answer.reverse

      if not calcAllAnswers and answers.len + answersSeq[runningNodeIndex].len > 1:
        runningNodeIndices.excl finishNodeIndices
        return true

    runningNodeIndices.excl finishNodeIndices
    false

  proc solveMultiThread(
      self: SolveNode,
      answers: var seq[SolveAnswer],
      moveCount: int,
      calcAllAnswers: bool,
      goal: Goal,
      steps: Steps,
  ) =
    ## Solves the Nazo Puyo at the node with multiple threads.
    ## This function requires that the field is settled and `answers` is empty.
    const
      SpawnWaitMs = 25
      SolveWaitMs = 50

    # NOTE: `TargetDepth == 3` is good; see https://github.com/24ik/pon2/issues/198
    # NOTE: `TargetDepth` should be less than 4 due to the limitations of Nim's built-in
    # sets, that is used by node indices (22^3 < int16.high < 22^4)
    const TargetDepth = 3

    var
      nodes = newSeq[SolveNode]()
      optPlacementsSeq = newSeq[seq[OptPlacement]]()
    self.childrenAtDepth TargetDepth,
      nodes, optPlacementsSeq, answers, moveCount, calcAllAnswers, goal, steps

    for answer in answers.mitems:
      answer.reverse

    if not calcAllAnswers and answers.len > 1:
      return

    let nodeCount = nodes.len
    var
      answersSeq = collect:
        for _ in 1 .. nodeCount:
          newSeq[SolveAnswer]()
      futures = newSeqOfCap[FlowVar[bool]](nodeCount)
      runningNodeIndices = set[int16]({})

    var nodeIndex = 0'i16
    while nodeIndex < nodeCount:
      if preferSpawn():
        futures.add spawn nodes[nodeIndex].solveSingleThread(
          answersSeq[nodeIndex].addr, moveCount, calcAllAnswers, goal, steps
        )

        runningNodeIndices.incl nodeIndex
        nodeIndex.inc

        continue

      let earlyReturned {.used.} = futures.checkSpawnFinished(
        answers, answersSeq, runningNodeIndices, optPlacementsSeq, calcAllAnswers
      )
      if not calcAllAnswers and earlyReturned:
        break

      sleep SpawnWaitMs

    while runningNodeIndices.card > 0:
      discard futures.checkSpawnFinished(
        answers, answersSeq, runningNodeIndices, optPlacementsSeq, calcAllAnswers
      )
      sleep SolveWaitMs

    answers &= answersSeq.concat

proc solve*(self: NazoPuyo, calcAllAnswers = true): seq[SolveAnswer] =
  ## Solves the Nazo Puyo.
  ## A single thread is used on JS backend; otherwise multiple threads are used.
  ## This function requires that the field is settled.
  if not self.goal.isSupported or self.puyoPuyo.steps.len == 0:
    return @[]

  let
    root = SolveNode.init self.puyoPuyo
    moveCount = self.puyoPuyo.steps.len
  var answers = newSeq[SolveAnswer]()

  when defined(js):
    root.solveSingleThread(
      answers,
      moveCount,
      calcAllAnswers,
      self.goal,
      self.puyoPuyo.steps,
      checkPruneFirst = true,
    )

    for answer in answers.mitems:
      answer.reverse
  else:
    root.solveMultiThread(
      answers, moveCount, calcAllAnswers, self.goal, self.puyoPuyo.steps
    )

  answers

# ------------------------------------------------
# Solve - Async
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    func initCompleteHandler(
        nodeIndex: int,
        optPlacementsSeq: seq[seq[OptPlacement]],
        answersSeqRef: ref seq[seq[SolveAnswer]],
        progressRef: ref tuple[now, total: int],
    ): StrErrorResult[seq[string]] -> void =
      ## Returns a handler called after a web worker job completes.
      (res: StrErrorResult[seq[string]]) => (
        block:
          if res.isOk:
            let answersResult = res.unsafeValue.parseSolveAnswers
            if answersResult.isOk:
              var answers = answersResult.unsafeValue
              for answer in answers.mitems:
                answer &= optPlacementsSeq[nodeIndex]
                answer.reverse

              answersSeqRef[][nodeIndex].assign answers
            else:
              console.error answersResult.error.cstring
          else:
            console.error res.error.cstring

          if not progressRef.isNil:
            progressRef[].now.inc
      )

    proc asyncSolve*(
        self: NazoPuyo,
        progressRef: ref tuple[now, total: int] = nil,
        calcAllAnswers = true,
    ): Future[seq[SolveAnswer]] {.async.} =
      ## Solves the Nazo Puyo asynchronously with web workers.
      ## This function requires that the field is settled.
      # NOTE: 2 and 3 show similar performance; 2 is chosen for faster `childrenAtDepth`
      const TargetDepth = 2

      if not progressRef.isNil:
        progressRef[] = (0, 0)

      if not self.goal.isSupported or self.puyoPuyo.steps.len == 0:
        if not progressRef.isNil:
          progressRef[] = (1, 1)

        return newSeq[SolveAnswer]()

      let rootNode = SolveNode.init self.puyoPuyo

      var
        nodes = newSeq[SolveNode]()
        optPlacementsSeq = newSeq[seq[OptPlacement]]()
        answers = newSeq[SolveAnswer]()

      rootNode.childrenAtDepth TargetDepth,
        nodes, optPlacementsSeq, answers, self.puyoPuyo.steps.len, calcAllAnswers,
        self.goal, self.puyoPuyo.steps

      for answer in answers.mitems:
        answer.reverse

      if not calcAllAnswers and answers.len > 1:
        if not progressRef.isNil:
          progressRef[] = (1, 1)

        return answers

      let nodeCount = nodes.len
      if not progressRef.isNil:
        if nodeCount == 0:
          progressRef[] = (1, 1)
        else:
          progressRef[] = (0, nodeCount)

      let answersSeqRef = new seq[seq[SolveAnswer]]
      answersSeqRef[] = collect:
        for _ in 1 .. nodeCount:
          newSeq[SolveAnswer]()

      {.push warning[Uninit]: off.}
      {.push warning[ProveInit]: off.}
      let futures = collect:
        for nodeIndex, node in nodes:
          webWorkerPool
          .run(node.toStrs(self.goal, self.puyoPuyo.steps))
          .then(
            initCompleteHandler(nodeIndex, optPlacementsSeq, answersSeqRef, progressRef)
          )
          .catch((error: Error) => console.error error)
      {.pop.}
      {.pop.}
      for future in futures:
        await future

      return answers & answersSeqRef[].concat

when isMainModule:
  let nazoPuyo =
    """
12連鎖以上するべし
======
[通]
......
....ob
....ob
....ob
bbyyog
bgryog
ggrrog
bbggoy
brrgoy
yryyoy
ybbyor
ybggor
rrrgor
------
bg|
rg|
ry|
by|
yb|
yr|
gr|
gb|""".parseNazoPuyo.unsafeValue
  echo nazoPuyo
