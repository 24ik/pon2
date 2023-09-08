import math
import options
import std/monotimes
import sugar
import times
import uri

import nazopuyo_core

import ../src/pon2pkg/core/solve

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

proc rashomon: Duration =
  let nazo = (
    "https://ishikawapuyo.net/simu/pn.html?c01cw2jo9jAbckAq9zqhacs9jAiSr_c1g1E1E1c1A1__200"
  ).parseUri.toNazoPuyo.get.nazoPuyo

  core result:
    discard nazo.solve

proc galaxy: Duration =
  let nazo = (
    "https://ishikawapuyo.net/simu/pn.html?P00P00PrAOqcOi9OriQpaQxAQzsNziN9aN_g1c1A1E1u16121q1__v0c"
  ).parseUri.toNazoPuyo.get.nazoPuyo

  core result:
    discard nazo.solve

when isMainModule:
  benchmark rashomon, 1
