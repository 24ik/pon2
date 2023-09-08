## This module implements the CUI permuter.
##

import browsers
import logging
import options
import sequtils
import strformat
import tables
import uri

import docopt
import nazopuyo_core
import puyo_core

import ./common
import ../core/permute

let logger = newConsoleLogger(lvlNotice, verboseFmtStr)

# ------------------------------------------------
# Entry Point
# ------------------------------------------------

proc runPermuter*(args: Table[string, Value]) {.inline.} =
  ## Runs the CUI permuter.
  let question = ($args["<question>"]).parseUri.toNazoPuyo
  if question.isNone:
    logger.log lvlError, "問題のURLが不正です．"

  var
    idx = 1
    nazo = question.get.nazoPuyo
  for pairsAnswer in question.get.nazoPuyo.permute(
    args["-f"].mapIt(it.parseNatural.Positive),
    not args["-D"].to_bool,
    args["-d"].to_bool,
    not args["-S"].to_bool,
  ):
    nazo.environment.pairs = pairsAnswer.pairs
    let
      questionUri = nazo.toUri
      answerUri = nazo.toUri some pairsAnswer.answer
    echo &"(Q{idx}) {questionUri}"
    echo &"(A{idx}) {answerUri}"
    echo ""

    if args["-B"].to_bool:
      ($questionUri).openDefaultBrowser
    if args["-b"].to_bool:
      ($answerUri).openDefaultBrowser

    idx.inc
