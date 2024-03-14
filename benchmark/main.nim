{.experimental: "strictDefs".}

import std/[math, monotimes, times]
import ../src/pon2pkg/[app, core]

template benchmark(
    desc: string, loop: Positive, prepare: untyped, measure: untyped
): untyped =
  var totalDuration = DurationZero

  for _ in 1 .. loop:
    prepare

    let t1 = getMonoTime()
    measure
    let t2 = getMonoTime()

    totalDuration += t2 - t1

  echo desc, ": ", totalDuration div loop

when isMainModule:
  let puyoPuyo19 = parsePuyoPuyo[TsuField](
    """
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
bg|3N"""
  )

  block:
    var field = initField[TsuField]()
    benchmark "Setter", 10 ^ 4:
      field = puyoPuyo19.field
    do:
      field[2, 3] = Cell.Red

  block:
    var field = initField[TsuField]()
    benchmark "Put", 10 ^ 4:
      field = puyoPuyo19.field
    do:
      field.put GreenYellow, Up2

  block:
    var field = initField[TsuField]()
    benchmark "Disppear", 10 ^ 4:
      field[5, 4] = Cell.Red
      field[5, 5] = Cell.Red
      field[5, 5] = Cell.Red
      field[6, 4] = Cell.Red
    do:
      discard field.disappear

  block:
    var field = initField[TsuField]()
    benchmark "Drop (Tsu)", 10 ^ 4:
      field[2, 3] = Cell.Red
    do:
      field.drop

  block:
    var field = initField[WaterField]()
    benchmark "Drop (Water)", 10 ^ 3:
      field[2, 3] = Cell.Red
    do:
      field.drop

  block:
    var puyoPuyo = initPuyoPuyo[TsuField]()
    benchmark "move (Level0)", 10 ^ 4:
      puyoPuyo = puyoPuyo19
    do:
      discard puyoPuyo.move0

  block:
    var puyoPuyo = initPuyoPuyo[TsuField]()
    benchmark "move (Level1)", 10 ^ 4:
      puyoPuyo = puyoPuyo19
    do:
      discard puyoPuyo.move1

  block:
    var puyoPuyo = initPuyoPuyo[TsuField]()
    benchmark "move (Level2)", 10 ^ 4:
      puyoPuyo = puyoPuyo19
    do:
      discard puyoPuyo.move2

  block:
    let nazo = parseNazoPuyo[TsuField](
      "c01cw2jo9jAbckAq9zqhacs9jAiSr_c1g1E1E1c1A1__200", Ishikawa
    )
    benchmark "Solve (Rashomon)", 1:
      discard
    do:
      discard nazo.solve
