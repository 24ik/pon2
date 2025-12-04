{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[monotimes, sequtils, stats, strformat, sugar, times]
# import ../src/pon2/[app]
import ../src/pon2/[core]
import ../src/pon2/app/[solve]
import ../src/pon2/private/[algorithm, math, results2]

func select(list: seq[Duration], n: int): Duration =
  ## Returns the n-th smallest value in the sequence.
  ## `n` is 0-indexed.
  if list.len <= 5:
    return list.sorted[n]

  let
    chunkCnt = list.len.ceilDiv 5
    chunks = list.distribute(chunkCnt, false)

    medians = collect:
      for chunk in chunks:
        chunk.sorted[chunk.len div 2]
    pivot = medians.select(medians.len div 2)

    lows = list.filterIt it < pivot
    highs = list.filterIt it > pivot
    pivots = list.filterIt it == pivot

  if n < lows.len:
    return lows.select n
  if n < lows.len + pivots.len:
    return pivot
  return highs.select n - lows.len - pivots.len

func median(list: seq[Duration]): Duration =
  ## Returns the median of the sequence.
  if list.len mod 2 == 0:
    (list.select(list.len div 2 - 1) + list.select(list.len div 2)) div 2
  else:
    list.select(list.len div 2)

func toStr(dur: Duration): string =
  ## Returns the custom string representation of the duration.
  if dur >= initDuration(hours = 1):
    let hours = dur.inSeconds.float / 3600
    "{hours:.2f} hours".fmt
  elif dur >= initDuration(minutes = 1):
    let minutes = dur.inMilliseconds.float / 60000
    "{minutes:.2f} mins".fmt
  elif dur >= initDuration(seconds = 1):
    let seconds = dur.inMilliseconds.float / 1000
    "{seconds:.2f} s".fmt
  elif dur >= initDuration(milliseconds = 1):
    let milliseconds = dur.inMicroseconds.float / 1000
    "{milliseconds:.2f} ms".fmt
  elif dur >= initDuration(microseconds = 1):
    let microseconds = dur.inNanoseconds.float / 1000
    "{microseconds:.2f} us".fmt
  elif dur >= initDuration(nanoseconds = 1):
    "{dur.inNanoseconds} ns".fmt
  elif dur == DurationZero:
    "0 ms"
  else:
    "Negative duration is not supported, but got: {dur}".fmt

func execResStr(desc: string, mean, sd, med: Duration, durCnt: int): string =
  ## Returns the string representation of execution result.
  # NOTE: format-string does not work in templates
  "[{desc}] {mean.toStr} +/- {sd.toStr} (Med: {med.toStr}), #Run: {durCnt}".fmt

template measureExecTime(desc: string, setup: untyped, body: untyped): untyped =
  ## Runs the `setup` and `body` repeatedly and shows the execution time of `body`.
  var
    durSum = DurationZero
    durs = newSeq[Duration]()
    stat: RunningStat

  while durSum < initDuration(milliseconds = 500):
    setup

    let t1 = getMonoTime()
    body
    let t2 = getMonoTime()

    let dur = t2 - t1

    durSum += dur
    durs.add dur
    stat.push dur.inNanoseconds.float

  echo execResStr(
    desc,
    initDuration(nanoseconds = stat.mean.int64),
    initDuration(nanoseconds = stat.standardDeviationS.int64),
    durs.median,
    durs.len,
  )

template measureExecTime(desc: string, body: untyped): untyped =
  ## Runs the `body` repeatedly and shows the execution time of `body`.
  desc.measureExecTime:
    discard
  do:
    body

when isMainModule:
  block:
    let field =
      """
[通]
.o....
.o..o.
.o.oo.
.o.oo.
.o.oo.
.o.oo.
.o.oo.
.o.oo.
.o.oo.
.o.oo.
.o.oo.
.o.oo.
.o.oo.""".parseField.unsafeValue

    "invalidPlacements".measureExecTime:
      discard field.invalidPlacements

  "place (Tsu)".measureExecTime:
    var field = Field.init
  do:
    field.place RedGreen, Right2

  "place (Water)".measureExecTime:
    var field = Field.init Rule.Water
  do:
    field.place RedGreen, Right2

  "pop".measureExecTime:
    var field = Field.init
  do:
    discard field.pop

  "dropGarbages (Tsu)".measureExecTime:
    var field = Field.init
  do:
    field.dropGarbages [Col0: 0, 1, 2, 3, 4, 5], false

  "dropGarbages (Water)".measureExecTime:
    var field = Field.init Rule.Water
  do:
    field.dropGarbages [Col0: 0, 1, 2, 3, 4, 5], false

  "settle (Tsu)".measureExecTime:
    var field = Field.init
  do:
    field.settle

  "settle (Water)".measureExecTime:
    var field = Field.init Rule.Water
  do:
    field.settle

  block:
    let
      field19 =
        """
[通]
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
rgybgy""".parseField.unsafeValue
      pair = BlueGreen
      plcmt = Up2

    "move (Tsu, not calcConn)".measureExecTime:
      var field = field19
    do:
      discard field.move(pair, plcmt, false)

    "move (Tsu, calcConn)".measureExecTime:
      var field = field19
    do:
      discard field.move(pair, plcmt, true)

  block:
    let
      field18 =
        """
[すいちゅう]
.....g
.rbrbr
gbrbrb
gbrbrb
gbrbrb
~~~~~~
rpypyr
rpypyr
rpypyr
bypygg
bgrbrg
bgrbrp
rgrbrp
pbgrbr""".parseField.unsafeValue
      pair = GreenBlue
      plcmt = Up0

    "move (Water, not calcConn)".measureExecTime:
      var field = field18
    do:
      discard field.move(pair, plcmt, false)

    "move (Water, calcConn)".measureExecTime:
      var field = field18
    do:
      discard field.move(pair, plcmt, true)

  "solve (Rashomon)".measureExecTime:
    let nazoPuyo =
      """
ぷよ全て消すべし
======
[通]
......
......
......
..ry..
.rryy.
.ggbb.
rrgbyy
rbrygy
yybgrr
ybbggr
rgryby
rrgbyy
ggoobb
------
rg|
bg|
by|
by|
rg|
ry|""".parseNazoPuyo.unsafeValue
  do:
    discard nazoPuyo.solve

  "solve (Galaxy)".measureExecTime:
    let nazoPuyo =
      """
12連鎖以上するべし
======
[通]
......
....ob
....ob
....ob
bbyyog
bgryog
ggrrog
bbggoy
brrgoy
yryyoy
ybbyor
ybggor
rrrgor
------
bg|
rg|
ry|
by|
yb|
yr|
gr|
gb|""".parseNazoPuyo.unsafeValue
  do:
    discard nazoPuyo.solve
