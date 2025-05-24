{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[random, sequtils, sets, sugar, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[marathon, nazopuyowrap, simulator]

when defined(js):
  import std/[asyncjs, sugar]
else:
  import chronos

# ------------------------------------------------
# Load / Property
# ------------------------------------------------

block: # load, dataLoaded, matchQueries, simulator
  var
    rng = 123.initRand
    marathon = Marathon.init rng

  check not marathon.dataLoaded
  marathon.load @[]
  check marathon.dataLoaded

  check marathon.matchQueries.len == 0

  var sim = Simulator.init PuyoPuyo[TsuField].init
  check marathon.simulator == sim

  sim.writeCell Cell.Green
  marathon.simulator.writeCell Cell.Green
  check marathon.simulator == sim

block: # asyncLoad
  var rng = 123.initRand
  when defined(js):
    var marathon = Marathon.init rng
    discard marathon.asyncLoad(@[]).then(() => (check marathon.dataLoaded)).catch(
        (err: Error) => (check false)
      )
  else:
    var marathon = new Marathon
    marathon[] = Marathon.init rng
    waitFor marathon.asyncLoad @[]
    check marathon[].dataLoaded

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

  marathon.match "rg"
  check marathon.matchQueries.len == 2
  check marathon.matchQueries.toHashSet == ["rgrg", "rgrb"].toHashSet

  marathon.match "gr"
  check marathon.matchQueries == @["grrb"]

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
  check marathon.matchQueries == @["bgyy"]

  marathon.match "cabb"
  check marathon.matchQueries == @["bgyy"]

block: # asyncMatch
  var
    rng = 123.initRand
    marathon = Marathon.init rng
  marathon.load @["rrgg", "rgrg", "rgbb"]

  when defined(js):
    discard marathon
      .asyncMatch("rr")
      .then(() => (check marathon.matchQueries == @["rrgg"]))
      .catch((err: Error) => (check false))
  else:
    var marathonRef = new Marathon
    marathonRef[] = marathon
    waitFor marathonRef.asyncMatch "rr"
    check marathonRef[].matchQueries == @["rrgg"]

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
    runIt marathon.simulator.nazoPuyoWrap:
      check not it.steps[0].pair.isDbl

  for _ in 1 .. 10:
    marathon.selectRandomQuery
    runIt marathon.simulator.nazoPuyoWrap:
      check not it.steps[0].pair.isDbl

  for _ in 1 .. 10:
    marathon.selectRandomQuery(fromMatched = false)
    runIt marathon.simulator.nazoPuyoWrap:
      check it.steps in queries.map (query: string) => query.parseSteps(Pon2).unsafeValue
