import math
import options
import std/monotimes
import sugar
import times

import nazopuyo_core

import ../src/pon2pkg/core/solve {.all.}

template benchmark(fn: () -> Duration, loop = 1.Positive) =
  let durations = collect:
    for _ in 0 ..< loop:
      fn()

  echo fn.astToStr, ": ", durations.sum div loop

template core(duration: var Duration, body: untyped) =
  let t1 = getMonoTime()
  body
  let t2 = getMonoTime()

  duration = t2 - t1

proc solveRashomon: Duration =
  let nazo = "https://ishikawapuyo.net/simu/pn.html?c01cw2jo9jAbckAq9zqhacs9jAiSr_c1g1E1E1c1A1__200".toNazo(true).get

  core result:
    discard nazo.solve

proc solveGalaxy: Duration =
  let nazo = "https://ishikawapuyo.net/simu/pn.html?P00P00PrAOqcOi9OriQpaQxAQzsNziN9aN_g1c1A1E1u16121q1__v0c".toNazo(true).get

  core result:
    discard nazo.solve

when isMainModule:
  benchmark solveRashomon, 1
