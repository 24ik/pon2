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

type Solution* = seq[Placement]
  ## Nazo Puyo solution.
  ## Elements corresponding to non-`PairPlace` steps are set to `Placement.None`.

when not defined(js):
  # NOTE: `ChildTargetDepth == 4` is good; see https://github.com/24ik/pon2/issues/260
  const
    SolvePollingMs = 50
    ChildTargetDepth = 4

  proc solveSingleThread(
      self: SolveNode,
      solutions: ptr seq[Solution],
      moveCount: int,
      calcAllSolutions: bool,
      goal: Goal,
      steps: Steps,
  ): bool =
    ## Solves the Nazo Puyo at the node with a single thread.
    ## This function requires that the field is settled and `solutions` is empty.
    ## `solutions` are set in reverse order.
    ## The return value has no meanings; only used to get FlowVar.
    self.solveSingleThread(
      solutions[], moveCount, calcAllSolutions, goal, steps, checkPruneFirst = false
    )
    false

  proc solveMultiThread(
      self: SolveNode,
      solutions: var seq[Solution],
      moveCount: int,
      calcAllSolutions: bool,
      goal: Goal,
      steps: Steps,
  ) =
    ## Solves the Nazo Puyo at the node with multiple threads.
    ## This function requires that the field is settled and `solutions` is empty.
    var
      nodes = newSeq[SolveNode]()
      placementsSeq = newSeq[seq[Placement]]()
    self.childrenAtDepth ChildTargetDepth,
      nodes, placementsSeq, solutions, moveCount, calcAllSolutions, goal, steps

    for solution in solutions.mitems:
      solution.reverse

    if not calcAllSolutions and solutions.len > 1:
      return

    var nodeToIndices = initTable[SolveNode, seq[int]](nodes.len)
    for nodeIndex, node in nodes:
      nodeToIndices.mgetOrPut(node, @[]).add nodeIndex

    let futureCount = nodeToIndices.len
    var
      solutionsSeq = collect:
        for _ in 1 .. futureCount:
          newSeq[Solution]()
      futures = newSeqOfCap[FlowVar[bool]](futureCount)

    block:
      var futureIndex = 0
      for node in nodeToIndices.keys:
        futures.add spawn node.solveSingleThread(
          solutionsSeq[futureIndex].addr, moveCount, calcAllSolutions, goal, steps
        )
        futureIndex += 1

    var
      completedCount = 0
      completedSeq = false.repeat futureCount
    while completedCount < futureCount:
      var futureIndex = 0
      for node in nodeToIndices.keys:
        if completedSeq[futureIndex] or not futures[futureIndex].isReady:
          futureIndex += 1
          continue

        let nodeIndices = nodeToIndices[node].unsafeValue
        for nodeIndex in nodeIndices:
          {.push warning[Uninit]: off.}
          solutions &=
            solutionsSeq[futureIndex].mapIt (it & placementsSeq[nodeIndex]).reversed
          {.pop.}

        if not calcAllSolutions and solutions.len > 1:
          return

        completedCount += 1
        completedSeq[futureIndex].assign true
        futureIndex += 1

      sleep SolvePollingMs

proc solve*(self: NazoPuyo, calcAllSolutions = true): seq[Solution] =
  ## Solves the Nazo Puyo.
  ## A single thread is used on JS backend; otherwise multiple threads are used.
  ## This function requires that the field is settled.
  if not self.goal.isSupported or self.puyoPuyo.steps.len == 0:
    return @[]

  let
    root = SolveNode.init self
    moveCount = self.puyoPuyo.steps.len
  var solutions = newSeq[Solution]()

  when defined(js):
    root.solveSingleThread(
      solutions,
      moveCount,
      calcAllSolutions,
      self.goal,
      self.puyoPuyo.steps,
      checkPruneFirst = true,
    )

    for solution in solutions.mitems:
      solution.reverse
  else:
    root.solveMultiThread(
      solutions, moveCount, calcAllSolutions, self.goal, self.puyoPuyo.steps
    )

  solutions

# ------------------------------------------------
# Solve - Async
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    # NOTE: 2 and 3 show similar performance; 2 is chosen for faster `childrenAtDepth`
    const ChildTargetDepthJs = 2

    func initCompleteHandler(
        nodeIndex: int,
        placementsSeq: seq[seq[Placement]],
        solutionsSeqRef: ref seq[seq[Solution]],
        progressRef: ref tuple[now, total: int],
    ): Pon2Result[seq[string]] -> void =
      ## Returns a handler called after a web worker job completes.
      (msgsResult: Pon2Result[seq[string]]) => (
        block:
          if msgsResult.isOk:
            let solutionsResult = msgsResult.unsafeValue.parseSolutions
            if solutionsResult.isOk:
              var solutions = solutionsResult.unsafeValue
              for solution in solutions.mitems:
                solution &= placementsSeq[nodeIndex]
                solution.reverse

              solutionsSeqRef[][nodeIndex].assign solutions
            else:
              console.error solutionsResult.error.cstring
          else:
            console.error msgsResult.error.cstring

          if not progressRef.isNil:
            progressRef[].now += 1
      )

    proc asyncSolve*(
        self: NazoPuyo,
        progressRef: ref tuple[now, total: int] = nil,
        calcAllSolutions = true,
    ): Future[seq[Solution]] {.async.} =
      ## Solves the Nazo Puyo asynchronously with web workers.
      ## This function requires that the field is settled.
      if not progressRef.isNil:
        progressRef[] = (0, 0)

      if not self.goal.isSupported or self.puyoPuyo.steps.len == 0:
        if not progressRef.isNil:
          progressRef[] = (1, 1)

        return newSeq[Solution]()

      let rootNode = SolveNode.init self

      var
        nodes = newSeq[SolveNode]()
        placementsSeq = newSeq[seq[Placement]]()
        solutions = newSeq[Solution]()

      rootNode.childrenAtDepth ChildTargetDepthJs,
        nodes, placementsSeq, solutions, self.puyoPuyo.steps.len, calcAllSolutions,
        self.goal, self.puyoPuyo.steps

      for solution in solutions.mitems:
        solution.reverse

      if not calcAllSolutions and solutions.len > 1:
        if not progressRef.isNil:
          progressRef[] = (1, 1)

        return solutions

      let nodeCount = nodes.len
      if not progressRef.isNil:
        if nodeCount == 0:
          progressRef[] = (1, 1)
        else:
          progressRef[] = (0, nodeCount)

      let solutionsSeqRef = new seq[seq[Solution]]
      solutionsSeqRef[] = collect:
        for _ in 1 .. nodeCount:
          newSeq[Solution]()

      {.push warning[Uninit]: off.}
      {.push warning[ProveInit]: off.}
      let futures = collect:
        for nodeIndex, node in nodes:
          webWorkerPool
          .run(node.toStrs(self.goal, self.puyoPuyo.steps))
          .then(
            initCompleteHandler(nodeIndex, placementsSeq, solutionsSeqRef, progressRef)
          )
          .catch((error: Error) => console.error error)
      {.pop.}
      {.pop.}
      for future in futures:
        await future

      return solutions & solutionsSeqRef[].concat
