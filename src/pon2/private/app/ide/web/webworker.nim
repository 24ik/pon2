## This module implements procedures that use web workers.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[dom, options, sequtils, strutils, uri]
import ../../[permute, solve]
import ../../../[webworker]
import
  ../../../../core/
    [field, fqdn, nazopuyo, pair, pairposition, position, puyopuyo, requirement]

type TaskKind* = enum
  ## Worker task kind.
  Solve = "solve"
  Permute = "permute"

# ------------------------------------------------
# Solve (async)
# ------------------------------------------------

const WaitLoopIntervalMs = 50

proc asyncSolve[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    results: ref seq[Option[seq[PairsPositions]]],
    reqKind: static RequirementKind,
    reqColor: static RequirementColor,
    earlyStopping: static bool,
    parallelCount: Positive,
) {.inline.} =
  ## Solves the nazo puyo.
  ## Solve results are stored in `results`.
  if not nazo.requirement.isSupported or nazo.moveCount == 0:
    results[] = @[some newSeq[PairsPositions](0)]
    return

  let rootNode = nazo.initNode
  if rootNode.canPrune(reqKind, reqColor):
    results[] = @[some newSeq[PairsPositions](0)]
    return

  let childNodes = rootNode.children(reqKind, reqColor)
  results[] = newSeqOfCap[Option[seq[PairsPositions]]](childNodes.len.succ)
  results[].add none seq[PairsPositions] # HACK: represent incompletion

  # result-register handler
  var interval: Interval
  proc handler(returnCode: WorkerReturnCode, messages: seq[string]) =
    case returnCode
    of Success:
      results[].add some messages.mapIt it.parsePairsPositions Pon2
      if results[].len == childNodes.len.succ:
        results[].del 0 # remove incompletion dummy
        interval.clearInterval
    of Failure:
      discard

  # setup workers
  let workers = new seq[Worker]
  workers[] = newSeqOfCap[Worker](parallelCount)
  for _ in 1 .. parallelCount:
    let worker = newWorker()
    worker.completeHandler = handler
    workers[].add worker

  # run workers
  var childIdx = 0
  proc runWorkers() =
    for worker in workers[]:
      if childIdx >= childNodes.len:
        break
      if worker.running:
        continue

      worker.run $Solve, $nazo.rule, childNodes[childIdx].toStr
      childIdx.inc

  interval = runWorkers.setInterval WaitLoopIntervalMs

proc asyncSolve[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    results: ref seq[Option[seq[PairsPositions]]],
    reqKind: static RequirementKind,
    earlyStopping: static bool,
    parallelCount: Positive,
) {.inline.} =
  ## Solves the nazo puyo.
  ## Solve results are stored in `results`.
  assert reqKind in {
    RequirementKind.Clear, DisappearCount, DisappearCountMore, ChainClear,
    ChainMoreClear, DisappearCountSametime, DisappearCountMoreSametime, DisappearPlace,
    DisappearPlaceMore, DisappearConnect, DisappearConnectMore,
  }

  case nazo.requirement.color
  of RequirementColor.All:
    nazo.asyncSolve results, reqKind, RequirementColor.All, earlyStopping, parallelCount
  of RequirementColor.Red:
    nazo.asyncSolve results, reqKind, RequirementColor.Red, earlyStopping, parallelCount
  of RequirementColor.Green:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Green, earlyStopping, parallelCount
  of RequirementColor.Blue:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Blue, earlyStopping, parallelCount
  of RequirementColor.Yellow:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Yellow, earlyStopping, parallelCount
  of RequirementColor.Purple:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Purple, earlyStopping, parallelCount
  of RequirementColor.Garbage:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Garbage, earlyStopping, parallelCount
  of RequirementColor.Color:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Color, earlyStopping, parallelCount

proc asyncSolve*[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    results: ref seq[Option[seq[PairsPositions]]],
    showProgress = false,
    earlyStopping: static bool = false,
    parallelCount: Positive = 6,
) {.inline.} =
  ## Solves the nazo puyo.
  ## Solve results are stored in `results`.
  const DummyColor = RequirementColor.All

  case nazo.requirement.kind
  of RequirementKind.Clear:
    nazo.asyncSolve results, RequirementKind.Clear, earlyStopping, parallelCount
  of DisappearColor:
    nazo.asyncSolve results, DisappearColor, DummyColor, earlyStopping, parallelCount
  of DisappearColorMore:
    nazo.asyncSolve results,
      DisappearColorMore, DummyColor, earlyStopping, parallelCount
  of DisappearCount:
    nazo.asyncSolve results, DisappearCount, earlyStopping, parallelCount
  of DisappearCountMore:
    nazo.asyncSolve results, DisappearCountMore, earlyStopping, parallelCount
  of Chain:
    nazo.asyncSolve results, Chain, DummyColor, earlyStopping, parallelCount
  of ChainMore:
    nazo.asyncSolve results, ChainMore, DummyColor, earlyStopping, parallelCount
  of ChainClear:
    nazo.asyncSolve results, ChainClear, earlyStopping, parallelCount
  of ChainMoreClear:
    nazo.asyncSolve results, ChainMoreClear, earlyStopping, parallelCount
  of DisappearColorSametime:
    nazo.asyncSolve results,
      DisappearColorSametime, DummyColor, earlyStopping, parallelCount
  of DisappearColorMoreSametime:
    nazo.asyncSolve results,
      DisappearColorMoreSametime, DummyColor, earlyStopping, parallelCount
  of DisappearCountSametime:
    nazo.asyncSolve results, DisappearCountSametime, earlyStopping, parallelCount
  of DisappearCountMoreSametime:
    nazo.asyncSolve results, DisappearCountMoreSametime, earlyStopping, parallelCount
  of DisappearPlace:
    nazo.asyncSolve results, DisappearPlace, earlyStopping, parallelCount
  of DisappearPlaceMore:
    nazo.asyncSolve results, DisappearPlaceMore, earlyStopping, parallelCount
  of DisappearConnect:
    nazo.asyncSolve results, DisappearConnect, earlyStopping, parallelCount
  of DisappearConnectMore:
    nazo.asyncSolve results, DisappearConnectMore, earlyStopping, parallelCount

# ------------------------------------------------
# Permute (async)
# ------------------------------------------------

proc asyncPermute*[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    results: ref seq[Option[PairsPositions]],
    fixMoves: seq[Positive],
    allowDouble: bool,
    allowLastDouble: bool,
    parallelCount: Positive = 6,
) {.inline.} =
  ## Permutes the pairs.
  ## Results are stored in `results`.
  let pairsPositionsSeq =
    nazo.allPairsPositionsSeq(fixMoves, allowDouble, allowLastDouble)
  results[] = newSeqOfCap[Option[PairsPositions]](pairsPositionsSeq.len.succ)
  results[].add none PairsPositions # HACK: represent incompletion

  # result-register handler
  var interval: Interval
  proc handler(returnCode: WorkerReturnCode, messages: seq[string]) =
    case returnCode
    of Success:
      if messages[0].parseBool:
        results[].add some messages[1].parsePairsPositions Pon2
      else:
        results[].add none PairsPositions

      if results[].len == pairsPositionsSeq.len.succ:
        results[].keepItIf it.isSome
        interval.clearInterval
    of Failure:
      discard

  # setup workers
  let workers = new seq[Worker]
  workers[] = newSeqOfCap[Worker](parallelCount)
  for _ in 1 .. parallelCount:
    let worker = newWorker()
    worker.completeHandler = handler
    workers[].add worker

  # run workers
  var pairsPositionsIdx = 0
  proc runWorkers() =
    for worker in workers[]:
      if pairsPositionsIdx >= pairsPositionsSeq.len:
        break
      if worker.running:
        continue

      var nazo2 = nazo
      nazo2.puyoPuyo.pairsPositions = pairsPositionsSeq[pairsPositionsIdx]
      worker.run $Permute, $nazo2.toUriQuery, $nazo2.puyoPuyo.field.rule
      pairsPositionsIdx.inc

  interval = runWorkers.setInterval WaitLoopIntervalMs
