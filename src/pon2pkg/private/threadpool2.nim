## This module implements thread pools.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

{.push warning[Deprecated]: off.}
import std/[os, macros, sequtils, threadpool, typetraits]
{.pop.}
import ./[misc]

const ParallelSleepMs = 8

macro parallelCollect*(res: var seq[untyped], workerCount: Positive,
                       body: untyped) =
  ## Multithread version of `collect`.
  ## The results are stored to `res`.
  runnableExamples:
    var res = newSeq[int](0)
    res.parallelCollect 2:
      for i in 0..<3:
        succ(i)

  expectKind body, nnkStmtList
  expectLen body, 1
  expectKind body[0], nnkForStmt
  expectLen body[0][2], 1

  let
    loopIdx = body[0][0]
    loopIter = body[0][1]
    spawnBody = body[0][2][0]

  result = quote do:
    var
      workersRunning = false.repeat `workerCount`
      futures = newSeq[FlowVar[res.elementType]](`workerCount`)

    for `loopIdx` in `loopIter`:
      var taskStarted = false
      while not taskStarted:
        for workerIdx in 0..<`workerCount`:
          if workersRunning[workerIdx]:
            if futures[workerIdx].isReady:
              `res`.add ^futures[workerIdx]
              workersRunning[workerIdx] = false

          if not workersRunning[workerIdx]:
            futures[workerIdx] = spawn `spawnBody`
            taskStarted = true
            workersRunning[workerIdx] = true
            break

        sleep ParallelSleepMs

    var runningWorkerIdxes = (0'i16..<`workerCount`.int16).toSeq.filterIt(
      workersRunning[it]).toSet2
    while runningWorkerIdxes.card > 0:
      for workerIdx in runningWorkerIdxes:
        if workersRunning[workerIdx]:
          `res`.add ^futures[workerIdx]
          runningWorkerIdxes.excl workerIdx

      sleep ParallelSleepMs
