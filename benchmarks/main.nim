{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[monotimes, sequtils, stats, strformat, sugar, times]
import ../src/pon2/[core]
import ../src/pon2/app/[solve]
import ../src/pon2/private/[algorithm, math]

func select[T](vals: seq[T], n: int): T =
  ## Returns the n-th smallest value in the sequence.
  ## `n` is 0-indexed.
  if vals.len <= 5:
    return vals.sorted[n]

  let
    chunkCnt = vals.len.ceilDiv 5
    chunks = vals.distribute(chunkCnt, spread = false)

    medians = collect:
      for chunk in chunks:
        chunk.sorted[chunk.len div 2]
    pivot = medians.select(medians.len div 2)

    lows = vals.filterIt it < pivot
    highs = vals.filterIt it > pivot
    pivots = vals.filterIt it == pivot

  if n < lows.len:
    return lows.select n
  if n < lows.len + pivots.len:
    return pivot

  highs.select n - lows.len - pivots.len

func median[T](vals: seq[T]): Duration =
  ## Returns the median of the sequence.
  if vals.len mod 2 == 0:
    (vals.select(vals.len div 2 - 1) + vals.select(vals.len div 2)) div 2
  else:
    vals.select(vals.len div 2)

func toStr(duration: Duration): string =
  ## Returns the custom string representation of the duration.
  if duration >= initDuration(hours = 1):
    let hours = duration.inSeconds.float / 3600
    "{hours:.2f} hours".fmt
  elif duration >= initDuration(minutes = 1):
    let minutes = duration.inMilliseconds.float / 60000
    "{minutes:.2f} mins".fmt
  elif duration >= initDuration(seconds = 1):
    let seconds = duration.inMilliseconds.float / 1000
    "{seconds:.2f} s".fmt
  elif duration >= initDuration(milliseconds = 1):
    let milliseconds = duration.inMicroseconds.float / 1000
    "{milliseconds:.2f} ms".fmt
  elif duration >= initDuration(microseconds = 1):
    let microseconds = duration.inNanoseconds.float / 1000
    "{microseconds:.2f} us".fmt
  elif duration >= initDuration(nanoseconds = 1):
    "{duration.inNanoseconds} ns".fmt
  elif duration == DurationZero:
    "0 ms"
  else:
    "Negative duration is not supported, but got: {duration}".fmt

template measureExecTime(desc: string, setup: untyped, body: untyped): untyped =
  ## Runs the `setup` and `body` repeatedly and shows the execution time of `body`.
  var
    durationSum = DurationZero
    durations = newSeq[Duration]()
    stat: RunningStat

  while durationSum < initDuration(milliseconds = 500):
    setup

    let t1 = getMonoTime()
    body
    let t2 = getMonoTime()

    let dur = t2 - t1

    durationSum += dur
    durations.add dur
    stat.push dur.inNanoseconds.float

  # NOTE: cannot use strformat due to template limitation
  echo "[" & desc & "] " & initDuration(nanoseconds = stat.mean.int64).toStr & " +/- " &
    initDuration(nanoseconds = stat.standardDeviationS.int64).toStr & " (Med: " &
    durations.median.toStr & "), #Run: " & $durations.len

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

  "dropNuisance (Tsu)".measureExecTime:
    var field = Field.init
  do:
    field.dropNuisance [Col0: 0, 1, 2, 3, 4, 5]

  "dropGarbages (Water)".measureExecTime:
    var field = Field.init Rule.Water
  do:
    field.dropNuisance [Col0: 0, 1, 2, 3, 4, 5]

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
      step = Step.init(BlueGreen, Up2)

    "move (Tsu, not calcConnection)".measureExecTime:
      var field = field19
    do:
      discard field.move(step, calcConnection = false)

    "move (Tsu, calcConnection)".measureExecTime:
      var field = field19
    do:
      discard field.move step

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
      step = Step.init(GreenBlue, Up0)

    "move (Water, not calcConnection)".measureExecTime:
      var field = field18
    do:
      discard field.move(step, calcConnection = false)

    "move (Water, calcConnection)".measureExecTime:
      var field = field18
    do:
      discard field.move step

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
