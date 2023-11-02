## This module implements CUI generator.
##

import logging
import options
import browsers
import strformat
import random
import tables
import uri

import docopt
import nazopuyo_core
import puyo_core

import ./common
import ../core/generate

let logger = newConsoleLogger(lvlNotice, verboseFmtStr)

proc runGenerator*(args: Table[string, Value]) {.inline.} =
  ## Runs the CUI generator.
  var rng = if args["-s"].kind == vkNone: initRand() else: args["-s"].parseNatural.get.initRand

  # requirement
  let
    kind = args["--rk"].parseRequirementKind.get
    req = (
      kind,
      (if kind in ColorKinds: args["--rc"].parseAbstractRequirementColor else: none AbstractRequirementColor),
      (if kind in NumberKinds: args["--rn"].parseRequirementNumber else: none RequirementNumber))

  # heights
  if ($args["-H"]).len != 6:
    logger.log lvlError, "-Hオプションには長さ6の文字列のみ指定できます．"
    return
  var heights: array[Column, Option[Natural]]
  for i, c in ($args["-H"]):
    heights[i.Column] = if c == '+': none Natural else: some c.parseNatural

  # generate
  for nazoIdx in 0 ..< args["-n"].parseNatural.get:
    let nazo = generate(
      (rng.rand int.low .. int.high),
      args["-r"].parseRule.get,
      args["-m"].parseNatural.get,
      req,
      args["-c"].parseNatural.get,
      heights,
      (color: args["--nc"].parseNatural.get, garbage: args["--ng"].parseNatural.get),
      (
        total: args["--tt"].parseNatural true,
        vertical: args["--tv"].parseNatural true,
        horizontal: args["--th"].parseNatural true,
        lShape: args["--tl"].parseNatural true),
      not args["-D"].to_bool,
      args["-d"].to_bool)
    if nazo.isNone:
      logger.log lvlError, "入力された条件を満たすなぞぷよは存在しません．"
      return

    let
      questionUri = nazo.get.question.toUri
      answerUri = nazo.get.question.toUri some nazo.get.answer
    echo &"(Q{nazoIdx.succ}) {questionUri}"
    echo &"(A{nazoIdx.succ}) {answerUri}"
    echo ""

    if args["-B"].to_bool:
      ($questionUri).openDefaultBrowser
    if args["-b"].to_bool:
      ($answerUri).openDefaultBrowser
