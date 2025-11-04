{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[random, sequtils, sets, sugar, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[marathon, nazopuyowrap, simulator]

# ------------------------------------------------
# Load / Property
# ------------------------------------------------

block: # load, isReady
  var
    rng = 123.initRand
    marathon = Marathon.init rng

  check not marathon.isReady

  marathon.load @["rr"]
  check marathon.isReady

block: # matchQueries, simulator
  var
    rng = 123.initRand
    marathon = Marathon.init rng

  check marathon.matchQueries.len == 0

  var sim = Simulator.init PuyoPuyo[TsuField].init
  check marathon.simulator == sim

  sim.writeCell Cell.Green
  marathon.simulator.writeCell Cell.Green
  check marathon.simulator == sim

# ------------------------------------------------
# Match
# ------------------------------------------------

block: # match
  var
    rng = 123.initRand
    marathon = Marathon.init rng

  marathon.load @["rrgg", "rgrg", "byby", "rgrb", "grrb", "bgyy"]

  marathon.match ""
  check marathon.matchQueries.len == 0

  marathon.match "r"
  check marathon.matchQueries.len == 3
  check marathon.matchQueries.toHashSet == ["rrgg", "rgrg", "rgrb"].toHashSet

  marathon.match "y"
  check marathon.matchQueries.len == 0

  marathon.match "rr"
  check marathon.matchQueries.toHashSet == ["rrgg"].toHashSet

  marathon.match "rg"
  check marathon.matchQueries.len == 2
  check marathon.matchQueries.toHashSet == ["rgrg", "rgrb"].toHashSet

  marathon.match "gr"
  check marathon.matchQueries.toHashSet == ["grrb"].toHashSet

  marathon.match ""
  check marathon.matchQueries.len == 0

  marathon.match "a"
  check marathon.matchQueries.len == 0

  marathon.match "ab"
  check marathon.matchQueries.len == 5
  check marathon.matchQueries.toHashSet ==
    ["rgrg", "byby", "rgrb", "grrb", "bgyy"].toHashSet

  marathon.match "bc"
  check marathon.matchQueries.len == 0

  marathon.match "abac"
  check marathon.matchQueries.len == 2
  check marathon.matchQueries.toHashSet == ["rgrb", "grrb"].toHashSet

  marathon.match "abc"
  check marathon.matchQueries.len == 2
  check marathon.matchQueries.toHashSet == ["rgrb", "grrb"].toHashSet

  marathon.match "abcc"
  check marathon.matchQueries.toHashSet == ["bgyy"].toHashSet

  marathon.match "cabb"
  check marathon.matchQueries.toHashSet == ["bgyy"].toHashSet

# ------------------------------------------------
# Simulator
# ------------------------------------------------

block: # selectQuery, selectRandomQuery
  var
    rng = 123.initRand
    marathon = Marathon.init rng

  let queries = @["rrgg", "rgrg", "rgbb"]
  marathon.load queries

  check marathon.matchQueries.len == 0

  marathon.selectQuery 0
  check marathon.simulator == Simulator.init PuyoPuyo[TsuField].init

  marathon.match "ab"

  for i in 0 ..< 2:
    marathon.selectQuery i
    unwrapNazoPuyo marathon.simulator.nazoPuyoWrap:
      check not it.steps[0].pair.isDbl

  for _ in 1 .. 5:
    marathon.selectRandomQuery
    unwrapNazoPuyo marathon.simulator.nazoPuyoWrap:
      check not it.steps[0].pair.isDbl

  for _ in 1 .. 5:
    marathon.selectRandomQuery(fromMatched = false)
    unwrapNazoPuyo marathon.simulator.nazoPuyoWrap:
      check it.steps in queries.map (query: string) => query.parseSteps(Pon2).unsafeValue
