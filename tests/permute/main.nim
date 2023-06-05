import options
import sequtils
import strutils
import unittest

import puyo_core

import ../../src/pon2pkg/core/permute

func toIps(url: string): string = url.replace("https://ishikawapuyo.net", "http://ips.karou.jp")

proc checkPermuteCore(
  url: string,
  results: seq[tuple[problem: string, solution: string]],
  fixMoves: seq[Positive],
  allowDouble: bool,
  allowLastDouble: bool,
  skipSwap: bool,
) =
  check url.permute(fixMoves, allowDouble, allowLastDouble, skipSwap, ISHIKAWAPUYO).toSeq.mapIt(it.get) == results
  check url.permute(fixMoves, allowDouble, allowLastDouble, skipSwap, IPS).toSeq.mapIt(it.get) ==
    results.mapIt (it[0].toIps, it[1].toIps)

proc checkPermute(
  url: string,
  results: seq[tuple[problem: string, solution: string]],
  fixMoves: seq[Positive],
  allowDouble: bool,
  allowLastDouble: bool,
  skipSwap: bool,
) =
  checkPermuteCore(url, results, fixMoves, allowDouble, allowLastDouble, skipSwap)
  checkPermuteCore(url.toIps, results, fixMoves, allowDouble, allowLastDouble, skipSwap)

proc main* =
  # ------------------------------------------------
  # Permute
  # ------------------------------------------------

  # permute
  block:
    let
      query = "https://ishikawapuyo.net/simu/pn.html?S00r0Mm6iOi_g1g1__u03"

      result1rbrb = (
        problem: "https://ishikawapuyo.net/simu/pn.html?S00r0Mm6iOi_q1q1__u03",
        solution: "https://ishikawapuyo.net/simu/pn.html?S00r0Mm6iOi_qcqc__u03")
      result1rbbr = (
        problem: "https://ishikawapuyo.net/simu/pn.html?S00r0Mm6iOi_q1g1__u03",
        solution: "https://ishikawapuyo.net/simu/pn.html?S00r0Mm6iOi_qcgC__u03")
      result1brbr = (
        problem: "https://ishikawapuyo.net/simu/pn.html?S00r0Mm6iOi_g1g1__u03",
        solution: "https://ishikawapuyo.net/simu/pn.html?S00r0Mm6iOi_gCgC__u03")
      result2 = (
        problem: "https://ishikawapuyo.net/simu/pn.html?S00r0Mm6iOi_e1s1__u03",
        solution: "https://ishikawapuyo.net/simu/pn.html?S00r0Mm6iOi_e0s2__u03")

    # allow double
    # w/o fixMoves
    checkPermute(query, @[result2, result1rbrb], newSeq[Positive](0), true, true, true)
    checkPermute(query, @[result2, result1rbrb], newSeq[Positive](0), true, true, false)
    # w/ fixMoves
    checkPermute(query, @[result1rbbr], @[2.Positive], true, true, true)
    checkPermute(query, @[result1rbbr], @[2.Positive], true, true, false)
    checkPermute(query, @[result1brbr], @[1.Positive, 2.Positive], true, true, true)
    checkPermute(query, @[result1brbr], @[1.Positive, 2.Positive], true, true, false)

    # not allow last double
    checkPermute(query, @[result1rbrb], newSeq[Positive](0), true, false, true)

    # not allow double
    checkPermute(query, @[result1rbrb], newSeq[Positive](0), false, false, true)
