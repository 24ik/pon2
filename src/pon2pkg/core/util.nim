## This module implements utility functions.
##

import algorithm
import math
import options
import os
import random
import sequtils
import sugar

const
  AppName = "pon2"
  DataDir* = (
    when defined(windows): "APPDATA".getEnv getHomeDir() / "AppData" / "Roaming"
    elif defined(macos): getHomeDir() / "Application Support"
    else: "XDG_DATA_HOME".getEnv getHomeDir() / ".local" / "share"
  ) / AppName
  ConfigDir* = (
    when defined(windows): "APPDATA".getEnv getHomeDir() / "AppData" / "Roaming"
    elif defined(macos): getHomeDir() / "Application Support"
    else: "XDG_CONFIG_HOME".getEnv getHomeDir() / ".config"
  ) / AppName

iterator zip*[T, U, V](s1: openArray[T], s2: openArray[U], s3: openArray[V]): (T, U, V) {.inline.} =
  ## Yields a combination of elements in the given arrays.
  let minLen = [s1.len, s2.len, s3.len].min
  for i in 0 ..< minLen:
    yield (s1[i], s2[i], s3[i])

func sample*[T](rng: var Rand, `array`: openArray[T], num: Natural): seq[T] {.inline.} =
  ## Returns num non-duplicates from the array randomly.
  var array2 = `array`.toSeq
  rng.shuffle array2
  return array2[0 ..< num]
  
func round(rng: var Rand, x: SomeNumber): int {.inline.} =
  ## Probabilistic round function.
  ## For example, rng.round(2.7) becomes 2 with a 30% probability and 3 with a 70% probability.
  result = x.int
  if rng.rand(1.0) < x.float - x.floor:
    result.inc

func split*(rng: var Rand, total: Natural, chunk: Positive, allowEmpty: bool): Option[seq[int]] {.inline.} =
  ## Splits the total number into chunks.
  ## If the splitting fails, returns none.
  if chunk == 1:
    if total == 0 and not allowEmpty:
      return
    else:
      return some @[total.int]

  if total == 1 and not allowEmpty:
    if chunk == 1:
      return some @[total.int]
    else:
      return

  # separate index
  var sepIdxesWithoutEnds: seq[int]
  if allowEmpty:
    sepIdxesWithoutEnds = collect:
      for _ in 0 ..< chunk.pred:
        rng.rand total
  else:
    if total < chunk:
      return

    var idxes = (1 .. total.pred).toSeq
    rng.shuffle idxes
    sepIdxesWithoutEnds = idxes[0 ..< chunk.pred]
  let sepIdxes = @[0] & sepIdxesWithoutEnds.sorted & @[total.int]

  let res = collect:
    for i in 0 ..< chunk:
      sepIdxes[i.succ] - sepIdxes[i]
  return some res

func split*(rng: var Rand, total: Natural, ratios: openArray[Option[Natural]]): Option[seq[int]] {.inline.} =
  ## Splits the total number into chunks following the distribution represented by the given ratios.
  ## None in the ratios means a random.
  ## If the all ratios are zero, splits randomly.
  ## If the splitting fails, returns none.
  if ratios.len == 0:
    return

  let
    givenConcreteRatio = ratios.allIt it.isSome
    givenRandomRatio = ratios.allIt it.isNone or it.get == 0
  if not givenConcreteRatio and not givenRandomRatio:
    return

  if givenConcreteRatio:
    while true:
      let ratioSum = sum ratios.mapIt it.get
      if ratioSum == 0:
        return rng.split(total, ratios.len, true)

      var
        res = newSeqOfCap[int] ratios.len
        last = total.int

      for mean in ratios.mapIt total * it.get / ratioSum:
        let num = rng.round mean

        res.add num
        last.dec num

      if (ratios[^1].get == 0 and last == 0) or (ratios[^1].get > 0 and last > 0):
        res.add last
        return some res
  else:
    let nums = rng.split(total, ratios.countIt it.isNone, false)
    if nums.isNone:
      return

    var
      res = newSeqOfCap[int] ratios.len
      idx = 0
    for ratio in ratios:
      if ratio.isNone:
        res.add nums.get[idx]
        idx.inc
      else:
        res.add 0

    return res.some
