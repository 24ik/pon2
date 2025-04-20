{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, math, monotimes, sequtils, stats, strformat, sugar, times]
import ../src/pon2/core/[field, pair, placement]

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

func execResStr(desc: string, mean, sd, med: Duration): string =
  ## Returns the string representation of execution result.
  # NOTE: format-string does not work in templates
  "[{desc}] {mean.toStr} +/- {sd.toStr} (Med: {med.toStr})".fmt

template measureExecTime(desc: string, setup: untyped, body: untyped): untyped =
  ## Runs the `setup` and `body` repeatedly and shows the execution time.
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
  )

when isMainModule:
  "put (Tsu)".measureExecTime:
    var field = TsuField.init
  do:
    field.put RedGreen, Right2

  "put (Water)".measureExecTime:
    var field = WaterField.init
  do:
    field.put RedGreen, Right2
