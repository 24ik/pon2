## This module implements Nazo Puyo solvers.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, options, sequtils, setutils, tables]
import ./[nazopuyo]
import ../core/[field, nazopuyo, pairposition, position, requirement]
import ../private/[misc]
import ../private/app/[solve as solveModule]

when not defined(js):
  {.push warning[Deprecated]: off.}
  import std/[os, threadpool]
  {.pop.}
  import suru

export solveModule.SolveAnswer

# ------------------------------------------------
# Solve
# ------------------------------------------------

proc solve[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    reqKind: static RequirementKind,
    reqColor: static RequirementColor,
    showProgress: static bool,
    earlyStopping: static bool,
    parallelCount: Positive,
): seq[SolveAnswer] {.inline.} =
  ## Solves the nazo puyo.
  ## `showProgress` and `parallelCount` is ignored on JS backend.
  if not nazo.requirement.isSupported or nazo.moveCount == 0:
    return @[]

  let rootNode = nazo.initNode
  if rootNode.canPrune(reqKind, reqColor):
    return @[]

  let childNodes = rootNode.children(reqKind, reqColor)

  when defined(js):
    result = @[]
    for (child, pos) in childNodes:
      var childResults = child.solve(nazo.moveCount, reqKind, reqColor, earlyStopping)
      for res in childResults.mitems:
        res.addFirst pos

      result &= childResults

      when earlyStopping:
        if result.len > 1:
          return
  else:
    const ParallelSolvingWaitIntervalMs = 10

    # setup progress bar
    when showProgress:
      var progressBar = initSuruBar()
      progressBar[0].total = childNodes.len
      progressBar.setup

      when earlyStopping:
        proc shutDownProgressBar() =
          progressBar.inc progressBar[0].total - progressBar[0].progress
          progressBar.update
          progressBar.finish

    # spawn tasks
    var
      threadsRunning = false.repeat parallelCount
      futures = newSeq[FlowVar[seq[Deque[Position]]]](parallelCount)
      results = newSeqOfCap[seq[Deque[Position]]](childNodes.len)
      positions = newSeq[Position](parallelCount)
    for (child, pos) in childNodes:
      var spawned = false
      while not spawned:
        for threadIdx in 0 ..< parallelCount:
          if threadsRunning[threadIdx] and futures[threadIdx].isReady:
            var answers = ^futures[threadIdx]
            for answer in answers.mitems:
              answer.addFirst positions[threadIdx]
            results.add answers

            threadsRunning[threadIdx] = false

            when showProgress:
              progressBar.inc
              progressBar.update

            when earlyStopping:
              if results.mapIt(it.len).sum2 > 1:
                when showProgress:
                  shutDownProgressBar()

                return results.concat

          if not threadsRunning[threadIdx]:
            futures[threadIdx] =
              spawn child.solve(nazo.moveCount, reqKind, reqColor, earlyStopping)
            spawned = true
            threadsRunning[threadIdx] = true
            positions[threadIdx] = pos

            break

          sleep ParallelSolvingWaitIntervalMs

    # wait running tasks
    var runningThreadIdxes =
      (0'i16 ..< parallelCount.int16).toSeq.filterIt(threadsRunning[it]).toSet2
    while runningThreadIdxes.card > 0:
      for threadIdx in runningThreadIdxes:
        if futures[threadIdx].isReady:
          var answers = ^futures[threadIdx]
          for answer in answers.mitems:
            answer.addFirst positions[threadIdx]
          results.add answers

          runningThreadIdxes.excl threadIdx

          when showProgress:
            progressBar.inc
            progressBar.update

          when earlyStopping:
            if results.mapIt(it.len).sum2 > 1:
              when showProgress:
                shutDownProgressBar()

              return results.concat

      sleep ParallelSolvingWaitIntervalMs

    result = results.concat

    when showProgress:
      progressBar.finish

proc solve[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    reqKind: static RequirementKind,
    showProgress: static bool,
    earlyStopping: static bool,
    parallelCount: Positive,
): seq[SolveAnswer] {.inline.} =
  ## Solves the nazo puyo.
  ## `showProgress` and `parallelCount` is ignored on JS backend.
  assert reqKind in {
    Clear, DisappearCount, DisappearCountMore, ChainClear, ChainMoreClear,
    DisappearCountSametime, DisappearCountMoreSametime, DisappearPlace,
    DisappearPlaceMore, DisappearConnect, DisappearConnectMore,
  }

  result =
    case nazo.requirement.color
    of RequirementColor.All:
      nazo.solve(
        reqKind, RequirementColor.All, showProgress, earlyStopping, parallelCount
      )
    of RequirementColor.Red:
      nazo.solve(
        reqKind, RequirementColor.Red, showProgress, earlyStopping, parallelCount
      )
    of RequirementColor.Green:
      nazo.solve(
        reqKind, RequirementColor.Green, showProgress, earlyStopping, parallelCount
      )
    of RequirementColor.Blue:
      nazo.solve(
        reqKind, RequirementColor.Blue, showProgress, earlyStopping, parallelCount
      )
    of RequirementColor.Yellow:
      nazo.solve(
        reqKind, RequirementColor.Yellow, showProgress, earlyStopping, parallelCount
      )
    of RequirementColor.Purple:
      nazo.solve(
        reqKind, RequirementColor.Purple, showProgress, earlyStopping, parallelCount
      )
    of RequirementColor.Garbage:
      nazo.solve(
        reqKind, RequirementColor.Garbage, showProgress, earlyStopping, parallelCount
      )
    of RequirementColor.Color:
      nazo.solve(
        reqKind, RequirementColor.Color, showProgress, earlyStopping, parallelCount
      )

proc solve*[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    showProgress: static bool = false,
    earlyStopping: static bool = false,
    parallelCount: Positive = processorCount(),
): seq[SolveAnswer] {.inline.} =
  ## Solves the nazo puyo.
  ## `showProgress` and `parallelCount` is ignored on JS backend.
  const DummyColor = RequirementColor.All

  result =
    case nazo.requirement.kind
    of Clear:
      nazo.solve(Clear, showProgress, earlyStopping, parallelCount)
    of DisappearColor:
      nazo.solve(DisappearColor, DummyColor, showProgress, earlyStopping, parallelCount)
    of DisappearColorMore:
      nazo.solve(
        DisappearColorMore, DummyColor, showProgress, earlyStopping, parallelCount
      )
    of DisappearCount:
      nazo.solve(DisappearCount, showProgress, earlyStopping, parallelCount)
    of DisappearCountMore:
      nazo.solve(DisappearCountMore, showProgress, earlyStopping, parallelCount)
    of Chain:
      nazo.solve(Chain, DummyColor, showProgress, earlyStopping, parallelCount)
    of ChainMore:
      nazo.solve(ChainMore, DummyColor, showProgress, earlyStopping, parallelCount)
    of ChainClear:
      nazo.solve(ChainClear, showProgress, earlyStopping, parallelCount)
    of ChainMoreClear:
      nazo.solve(ChainMoreClear, showProgress, earlyStopping, parallelCount)
    of DisappearColorSametime:
      nazo.solve(
        DisappearColorSametime, DummyColor, showProgress, earlyStopping, parallelCount
      )
    of DisappearColorMoreSametime:
      nazo.solve(
        DisappearColorMoreSametime, DummyColor, showProgress, earlyStopping,
        parallelCount,
      )
    of DisappearCountSametime:
      nazo.solve(DisappearCountSametime, showProgress, earlyStopping, parallelCount)
    of DisappearCountMoreSametime:
      nazo.solve(DisappearCountMoreSametime, showProgress, earlyStopping, parallelCount)
    of DisappearPlace:
      nazo.solve(DisappearPlace, showProgress, earlyStopping, parallelCount)
    of DisappearPlaceMore:
      nazo.solve(DisappearPlaceMore, showProgress, earlyStopping, parallelCount)
    of DisappearConnect:
      nazo.solve(DisappearConnect, showProgress, earlyStopping, parallelCount)
    of DisappearConnectMore:
      nazo.solve(DisappearConnectMore, showProgress, earlyStopping, parallelCount)
