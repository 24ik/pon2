## This module implements Nazo Puyo solvers.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm]
import ../[core]
import ../private/[core, macros]
import ../private/app/[solve]

export core

when defined(js) or defined(nimsuggest):
  import std/[dom]
  import ../private/[strutils]

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
  proc solveSingleThread[F: TsuField or WaterField](
      self: SolveNode[F],
      answers: ptr seq[SolveAnswer],
      moveCnt: int,
      goal: Goal,
      steps: Steps,
      calcAllAnswers: static bool,
  ): bool =
    ## Solves the Nazo Puyo at the node with a single thread.
    ## This function requires that the field is settled and `answers` is empty.
    ## `answers` is set in reverse order.
    ## `result` has no meanings; only used to get FlowVar.
    # NOTE: non-static arguments should be placed before static ones due to `spawn` bug.
    self.solveSingleThread(
      answers[], moveCnt, calcAllAnswers, goal, steps, checkPruneFirst = false
    )
    true

  func checkSpawnFinished(
      futures: seq[FlowVar[bool]],
      answers: var seq[SolveAnswer],
      answersSeq: var seq[seq[SolveAnswer]],
      runningNodeIndices: var set[int16],
      optPlcmtsSeq: seq[seq[OptPlacement]],
      calcAllAnswers: static bool,
  ): bool =
    ## Checks all the spawned threads and reflects results if they have finished.
    ## Returns `true` if early-returned.
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
          runningNodeIndices.excl finishNodeIndices
          return true

    runningNodeIndices.excl finishNodeIndices
    false

  proc solveMultiThread[F: TsuField or WaterField](
      self: SolveNode[F],
      answers: var seq[SolveAnswer],
      moveCnt: int,
      calcAllAnswers: static bool,
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
      nodes = newSeq[SolveNode[F]]()
      optPlcmtsSeq = newSeq[seq[OptPlacement]]()
    self.childrenAtDepth TargetDepth,
      nodes, optPlcmtsSeq, answers, moveCnt, calcAllAnswers, goal, steps

    for ans in answers.mitems:
      ans.reverse

    when not calcAllAnswers:
      if answers.len > 1:
        return

    let nodeCnt = nodes.len
    var
      answersSeq = collect:
        for _ in 1 .. nodeCnt:
          newSeq[SolveAnswer]()
      futures = newSeqOfCap[FlowVar[bool]](nodeCnt)
      runningNodeIndices = set[int16]({})

    var nodeIdx = 0'i16
    while nodeIdx < nodeCnt:
      if preferSpawn():
        futures.add spawn nodes[nodeIdx].solveSingleThread(
          answersSeq[nodeIdx].addr, moveCnt, goal, steps, calcAllAnswers
        )

        runningNodeIndices.incl nodeIdx
        nodeIdx.inc

        continue

      let earlyReturned {.used.} = futures.checkSpawnFinished(
        answers, answersSeq, runningNodeIndices, optPlcmtsSeq, calcAllAnswers
      )
      when not calcAllAnswers:
        if earlyReturned:
          break

      sleep SpawnWaitMs

    while runningNodeIndices.card > 0:
      discard futures.checkSpawnFinished(
        answers, answersSeq, runningNodeIndices, optPlcmtsSeq, calcAllAnswers
      )
      sleep SolveWaitMs

    answers &= answersSeq.concat

proc solve*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], calcAllAnswers: static bool = true
): seq[SolveAnswer] =
  ## Solves the Nazo Puyo.
  ## A single thread is used on JS backend; otherwise multiple threads are used.
  ## This function requires that the field is settled.
  if not nazo.goal.isSupported or nazo.puyoPuyo.steps.len == 0:
    return @[]

  let
    root = SolveNode[F].init nazo.puyoPuyo
    moveCnt = nazo.puyoPuyo.steps.len
  var answers = newSeq[SolveAnswer]()

  when defined(js):
    root.solveSingleThread(
      answers,
      moveCnt,
      calcAllAnswers,
      nazo.goal,
      nazo.puyoPuyo.steps,
      checkPruneFirst = true,
    )

    for ans in answers.mitems:
      ans.reverse
  else:
    root.solveMultiThread(
      answers, moveCnt, calcAllAnswers, nazo.goal, nazo.puyoPuyo.steps
    )

  answers

# ------------------------------------------------
# Solve - Async
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    func initCompleteHandler(
        nodeIdx: int,
        optPlcmtsSeq: seq[seq[OptPlacement]],
        answersSeqRef: ref seq[seq[SolveAnswer]],
        progressRef: ref tuple[now, total: int],
    ): Res[seq[string]] -> void =
      ## Returns a handler called after a web worker job completes.
      (res: Res[seq[string]]) => (
        block:
          if res.isOk:
            let answersRes = res.unsafeValue.parseSolveAnswers
            if answersRes.isOk:
              var answers = answersRes.unsafeValue
              for ans in answers.mitems:
                ans &= optPlcmtsSeq[nodeIdx]
                ans.reverse

              answersSeqRef[][nodeIdx].assign answers
            else:
              console.error answersRes.error.cstring
          else:
            console.error res.error.cstring

          if not progressRef.isNil:
            progressRef[].now.inc
      )

    proc asyncSolve*[F: TsuField or WaterField](
        nazo: NazoPuyo[F],
        progressRef: ref tuple[now, total: int] = nil,
        calcAllAnswers: static bool = true,
    ): Future[seq[SolveAnswer]] {.async.} =
      ## Solves the Nazo Puyo asynchronously with web workers.
      ## This function requires that the field is settled.
      # NOTE: 2 and 3 show similar performance; 2 is chosen for faster `childrenAtDepth`
      const TargetDepth = 2

      if not progressRef.isNil:
        progressRef[] = (0, 0)

      if not nazo.goal.isSupported or nazo.puyoPuyo.steps.len == 0:
        if not progressRef.isNil:
          progressRef[] = (1, 1)

        return newSeq[SolveAnswer]()

      let rootNode = SolveNode[F].init nazo.puyoPuyo

      var
        nodes = newSeq[SolveNode[F]]()
        optPlcmtsSeq = newSeq[seq[OptPlacement]]()
        answers = newSeq[SolveAnswer]()

      rootNode.childrenAtDepth TargetDepth,
        nodes, optPlcmtsSeq, answers, nazo.puyoPuyo.steps.len, calcAllAnswers,
        nazo.goal, nazo.puyoPuyo.steps

      for ans in answers.mitems:
        ans.reverse

      when not calcAllAnswers:
        if answers.len > 1:
          if not progressRef.isNil:
            progressRef[] = (1, 1)

          return answers

      let nodeCnt = nodes.len
      if not progressRef.isNil:
        if nodeCnt == 0:
          progressRef[] = (1, 1)
        else:
          progressRef[] = (0, nodeCnt)

      let answersSeqRef = new seq[seq[SolveAnswer]]
      answersSeqRef[] = collect:
        for _ in 1 .. nodeCnt:
          newSeq[SolveAnswer]()

      {.push warning[Uninit]: off.}
      {.push warning[ProveInit]: off.}
      let futures = collect:
        for nodeIdx, node in nodes:
          webWorkerPool
          .run(node.toStrs(nazo.goal, nazo.puyoPuyo.steps))
          .then(initCompleteHandler(nodeIdx, optPlcmtsSeq, answersSeqRef, progressRef))
          .catch((e: Error) => console.error e)
      {.pop.}
      {.pop.}
      for future in futures:
        await future

      return answers & answersSeqRef[].concat
