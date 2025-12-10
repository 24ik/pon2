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
  import ../private/[assign, tables]

  {.push warning[Deprecated]: off.}
  import std/[threadpool]
  {.pop.}

type SolveAnswer* = seq[Placement]
  ## Nazo Puyo answer.
  ## Elements corresponding to non-`PairPlace` steps are set to `NonePlacement`.

when not defined(js):
  # NOTE: `ChildTargetDepth == 4` is good; see https://github.com/24ik/pon2/issues/260
  const
    SolvePollingMs = 50
    ChildTargetDepth = 4

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
    var
      nodes = newSeq[SolveNode]()
      placementsSeq = newSeq[seq[Placement]]()
    self.childrenAtDepth ChildTargetDepth,
      nodes, placementsSeq, answers, moveCount, calcAllAnswers, goal, steps

    for answer in answers.mitems:
      answer.reverse

    if not calcAllAnswers and answers.len > 1:
      return

    var nodeToIndices = initTable[SolveNode, seq[int]](nodes.len)
    for nodeIndex, node in nodes:
      nodeToIndices.mgetOrPut(node, @[]).add nodeIndex

    let futureCount = nodeToIndices.len
    var
      answersSeq = collect:
        for _ in 1 .. futureCount:
          newSeq[SolveAnswer]()
      futures = newSeqOfCap[FlowVar[bool]](futureCount)

    block:
      var futureIndex = 0
      for node in nodeToIndices.keys:
        futures.add spawn node.solveSingleThread(
          answersSeq[futureIndex].addr, moveCount, calcAllAnswers, goal, steps
        )
        futureIndex.inc

    var
      completedCount = 0
      completedSeq = false.repeat futureCount
    while completedCount < futureCount:
      var futureIndex = 0
      for node in nodeToIndices.keys:
        if completedSeq[futureIndex] or not futures[futureIndex].isReady:
          futureIndex.inc
          continue

        let nodeIndices = nodeToIndices[node].unsafeValue
        for nodeIndex in nodeIndices:
          {.push warning[Uninit]: off.}
          answers &=
            answersSeq[futureIndex].mapIt (it & placementsSeq[nodeIndex]).reversed
          {.pop.}

        if not calcAllAnswers and answers.len > 1:
          return

        completedCount.inc
        completedSeq[futureIndex].assign true
        futureIndex.inc

      sleep SolvePollingMs

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
    # NOTE: 2 and 3 show similar performance; 2 is chosen for faster `childrenAtDepth`
    const ChildTargetDepth = 2

    func initCompleteHandler(
        nodeIndex: int,
        placementsSeq: seq[seq[Placement]],
        answersSeqRef: ref seq[seq[SolveAnswer]],
        progressRef: ref tuple[now, total: int],
    ): Pon2Result[seq[string]] -> void =
      ## Returns a handler called after a web worker job completes.
      (res: Pon2Result[seq[string]]) => (
        block:
          if res.isOk:
            let answersResult = res.unsafeValue.parseSolveAnswers
            if answersResult.isOk:
              var answers = answersResult.unsafeValue
              for answer in answers.mitems:
                answer &= placementsSeq[nodeIndex]
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
      if not progressRef.isNil:
        progressRef[] = (0, 0)

      if not self.goal.isSupported or self.puyoPuyo.steps.len == 0:
        if not progressRef.isNil:
          progressRef[] = (1, 1)

        return newSeq[SolveAnswer]()

      let rootNode = SolveNode.init self.puyoPuyo

      var
        nodes = newSeq[SolveNode]()
        placementsSeq = newSeq[seq[Placement]]()
        answers = newSeq[SolveAnswer]()

      rootNode.childrenAtDepth ChildTargetDepth,
        nodes, placementsSeq, answers, self.puyoPuyo.steps.len, calcAllAnswers,
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
            initCompleteHandler(nodeIndex, placementsSeq, answersSeqRef, progressRef)
          )
          .catch((error: Error) => console.error error)
      {.pop.}
      {.pop.}
      for future in futures:
        await future

      return answers & answersSeqRef[].concat
