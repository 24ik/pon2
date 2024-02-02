## This module implements permuters.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques]
import ./[nazopuyo, solve]
import ../corepkg/[field, pair, position]
import ../private/nazopuyo/[permute]

when not defined(js):
  import std/[cpuinfo]
  import suru

# ------------------------------------------------
# Permute
# ------------------------------------------------

iterator permute*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], fixMoves: seq[Positive], allowDouble: bool,
    allowLastDouble: bool, showProgress = false, parallelCount: Positive =
      when defined(js): 1 else: max(1, countProcessors())):
    tuple[pairs: Pairs, answer: Positions] {.inline.} =
  ## Yields pairs and answer of the nazo puyo that is obtained by permuting
  ## pairs and has a unique solution.
  let pairsSeq = nazo.allPairsSeq(fixMoves, allowDouble, allowLastDouble)

  when not defined(js):
    var bar: SuruBar
    if showProgress:
      bar = initSuruBar()
      bar[0].total = pairsSeq.len
      bar.setup

  for pairs in pairsSeq:
    var nazo2 = nazo
    nazo2.environment.pairs = pairs

    let answers =
      nazo2.solve(earlyStopping = true, parallelCount = parallelCount)

    when not defined(js):
      bar.inc
      bar.update

    if answers.len == 1:
      yield (pairs, answers[0])

  when not defined(js):
    if showProgress:
      bar.finish
