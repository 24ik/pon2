## This module implements the database CUI.
##

import options
import sequtils
import strformat
import tables
import uri

import docopt
import nazopuyo_core

import ./common
import ../core/db

proc runDb*(args: Table[string, Value]) {.inline.} =
  ## Runs the database CUI.
  var db = loadDatabase()

  if args["add"] or args["a"]:
    let question = ($args["<question>"]).parseUri.toNazoPuyo
    if question.isNone:
      echo "問題のURLが不正です．"
      return

    let answers = (@(args["<answers>"]).deduplicate true).mapIt it.parseUri.toNazoPuyo
    if answers.anyIt it.isNone:
      echo "解答に不正なURLが含まれています．"
      return
    if answers.anyIt it.get.positions.isNone:
      echo "解答に操作が含まれていないURLが含まれています．"
      return

    db.add question.get.nazoPuyo, answers.mapIt(it.get.positions.get)
  elif args["delete"] or args["d"]:
    for url in @(args["<question>"]):
      let question = ($args["<question>"]).parseUri.toNazoPuyo
      if question.isNone:
        echo "問題のURLが不正です．"
        return

      db.del question.get.nazoPuyo
  elif args["find"] or args["f"]:
    var idx = 1
    for nazo in db.find(
      some args["--fk"].mapIt it.parseRequirementKind,
      some args["--fm"].mapIt it.parseNatural.Positive,
    ):
      let questionUri = nazo.nazoPuyo.toUri
      echo &"(Q{idx}) {questionUri}"

      for answerIdx, answer in nazo.answers:
        let answerUri = nazo.nazoPuyo.toUri some answer
        echo &"(A{idx}-{answerIdx}) {answerUri}"

      echo ""
      idx.inc
  else:
    doAssert false

  db.saveDatabase
