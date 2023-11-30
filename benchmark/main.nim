{.experimental: "strictDefs".}

import std/[math, options, monotimes, times, uri]
import ../src/pon2pkg/corepkg/[cell, field, environment, pair, position]
import ../src/pon2pkg/nazopuyopkg/[nazopuyo, solve]

template benchmark(desc: string, loop: Positive, prepare: untyped,
                   measure: untyped): untyped =
  var totalDuration = DurationZero

  for _ in 1..loop:
    prepare

    let t1 = getMonoTime()
    measure
    let t2 = getMonoTime()

    totalDuration += t2 - t1

  echo desc, ": ", totalDuration div loop

when isMainModule:
  let env19 = parseTsuEnvironment("""
by.yrr
gb.gry
rbgyyr
gbgyry
ryrgby
yrgbry
ryrgbr
ryrgbr
rggbyb
gybgbb
rgybgy
rgybgy
rgybgy
------
bg""").environment

  block:
    var field = zeroTsuField()
    benchmark "Setter", 10 ^ 4:
      field = env19.field
    do:
      field[2, 3] = Cell.Red

  block:
    var field = zeroTsuField()
    benchmark "Put", 10 ^ 4:
      field = env19.field
    do:
      field.put GreenYellow, Up2

  block:
    var field = zeroTsuField()
    benchmark "Disppear", 10 ^ 4:
      field[5, 4] = Cell.Red
      field[5, 5] = Cell.Red
      field[5, 5] = Cell.Red
      field[6, 4] = Cell.Red
    do:
      discard field.disappear

  block:
    var field = zeroTsuField()
    benchmark "Drop (Tsu)", 10 ^ 4:
      field[2, 3] = Cell.Red
    do:
      field.drop

  block:
    var field = zeroWaterField()
    benchmark "Drop (Water)", 10 ^ 3:
      field[2, 3] = Cell.Red
    do:
      field.drop

  block:
    var env = initTsuEnvironment 0
    benchmark "move (Vanilla)", 10 ^ 4:
      env = env19
    do:
      env.move Up3, false

  block:
    var env = initTsuEnvironment 0
    benchmark "move (Rough)", 10 ^ 4:
      env = env19
    do:
      discard env.moveWithRoughTracking(Up3, false)

  block:
    var env = initTsuEnvironment 0
    benchmark "move (Detail)", 10 ^ 4:
      env = env19
    do:
      discard env.moveWithDetailTracking(Up3, false)
  block:
    var env = initTsuEnvironment 0
    benchmark "move (Full)", 10 ^ 4:
      env = env19
    do:
      discard env.moveWithFullTracking(Up3, false)

  block:
    let nazo = (
      "https://ishikawapuyo.net/simu/pn.html?" &
      "c01cw2jo9jAbckAq9zqhacs9jAiSr_c1g1E1E1c1A1__200"
    ).parseUri.parseTsuNazoPuyo.nazoPuyo

    benchmark "Solve (Rashomon)", 1:
      discard
    do:
      discard nazo.solve

  block:
    let nazo = (
      "https://ishikawapuyo.net/simu/pn.html?" &
      "P00P00PrAOqcOi9OriQpaQxAQzsNziN9aN_g1c1A1E1u16121q1__v0c"
    ).parseUri.parseTsuNazoPuyo.nazoPuyo

    benchmark "Solve (Galaxy)", 1:
      discard
    do:
      discard nazo.solve
