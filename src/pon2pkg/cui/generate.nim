## This module implements generator CUI.
##

import options
import browsers
import strformat
import random
import tables

import docopt
import nazopuyo_core
import puyo_core

import ./util
import ../core/generate

# ------------------------------------------------
# Entry Point
# ------------------------------------------------

proc runGenerator*(args: Table[string, Value]) {.inline.} =
  ## Runs the generator CUI.

  var rng = if args["-s"].kind == vkNone: initRand() else: args["-s"].parseNatural.get.initRand

  # requirement
  let
    reqKind = args["--rk"].parseRequirementKind.get
    reqColor = some AbstractRequirementColor.low.succ args["--rc"].parseNatural.get
    reqNum = RequirementNumber args["--rn"].parseNatural.get
  if reqNum notin RequirementNumber.low .. RequirementNumber.high:
    echo "--rnオプションに扱えない範囲の数値が入力されました．"
    return
  let req = (
    kind: reqKind,
    color: (if reqKind in RequirementKindsWithColor: reqColor else: none AbstractRequirementColor),
    num: (if reqKind in RequirementKindsWithNum: some reqNum else: none RequirementNumber),
  ).AbstractRequirement

  # heights
  if ($args["-H"]).len != 6:
    echo "-Hオプションには長さ6の文字列のみ指定できます．"
    return
  var heights: array[Col, Option[Natural]]
  for i, c in ($args["-H"]):
    heights[Col.low.succ i] = if c == '+': none Natural else: some c.parseNatural

  for i in 0 ..< args["-n"].parseNatural.get:
    let
      seed = rng.rand int.low .. int.high
      res = generate(
        seed,
        args["-m"].parseNatural.get,
        req,
        args["-c"].parseNatural.get,
        heights,
        (color: args["--nc"].parseNatural.get, garbage: args["--ng"].parseNatural.get),
        (
          total: args["--tt"].parseNatural true,
          vertical: args["--tv"].parseNatural true,
          horizontal: args["--th"].parseNatural true,
          lShape: args["--tl"].parseNatural true,
        ),
        not args["-D"].to_bool,
        args["-d"].to_bool)

    if res.isNone:
      echo "入力された条件を満たすなぞぷよは存在しません．"
      return

    let
      (problem, solution) = res.get
      domain = if args["-i"].to_bool: IPS else: ISHIKAWAPUYO
      problemUrl = problem.toUrl(domain = domain)
      solutionUrl = problem.toUrl(some solution, domain)

    echo &"(Q{i.succ}) {problemUrl}"
    echo &"(A{i.succ}) {solutionUrl}"
    echo ""

    if args["-B"].to_bool:
      problemUrl.openDefaultBrowser
    if args["-b"].to_bool:
      solutionUrl.openDefaultBrowser
