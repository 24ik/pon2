## This module implements the solver CUI.
##

import browsers
import options
import strformat
import tables
import uri

import docopt
import nazopuyo_core
import puyo_core

import ../core/solve

proc runSolver*(args: Table[string, Value]) {.inline.} =
  ## Runs the solver CUI.
  let question = ($args["<question>"]).parseUri.toNazoPuyo
  if question.isNone:
    echo "問題のURLが不正です．"
    return

  if args["-B"].to_bool:
    ($args["<question>"]).openDefaultBrowser

  for answerIdx, answer in question.get.nazoPuyo.solve:
    let answerUri = question.get.nazoPuyo.toUri some answer
    echo &"({answerIdx.succ}) {answerUri}"

    if args["-b"].to_bool:
      ($answerUri).openDefaultBrowser
