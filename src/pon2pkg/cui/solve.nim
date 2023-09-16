## This module implements the CUI solver.
##

import browsers
import logging
import options
import strformat
import tables
import uri

import docopt
import nazopuyo_core
import puyo_core

import ../core/solve

let logger = newConsoleLogger(lvlNotice, verboseFmtStr)

proc runSolver*(args: Table[string, Value]) {.inline.} =
  ## Runs the CUI solver.
  let question = ($args["<question>"]).parseUri.toNazoPuyo
  if question.isNone:
    logger.log lvlError, "問題のURLが不正です．"
    return

  if args["-B"].to_bool:
    ($args["<question>"]).openDefaultBrowser

  for answerIdx, answer in question.get.nazoPuyo.solve(showProgress = true):
    let answerUri = question.get.nazoPuyo.toUri some answer
    echo &"({answerIdx.succ}) {answerUri}"

    if args["-b"].to_bool:
      ($answerUri).openDefaultBrowser
