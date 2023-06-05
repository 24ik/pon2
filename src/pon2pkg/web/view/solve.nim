## This module implements the solver view.
##

import options
import sequtils
import std/asyncjs

include karax/prelude

import ./message
import ./simulator
import ../../core/solve

proc solverField*: VNode =
  ## Returns the solver view.
  const ProblemFormId = "question-form"

  # FIXME: proper async
  proc solve(url: kstring) {.async.} =
    let solutions = ($url).solve
    if solutions.isNone:
      messages = @[kstring"URL形式エラー"]
      return

    simulatorUrl = kstring""

    messages = solutions.get.mapIt it.kstring
    if messages.len == 1:
      simulatorUrl = messages[0]

  proc solveAndWrite =
    let questionUrl = ProblemFormId.getVNodeById.getInputText
    if questionUrl == kstring"":
      return

    discard questionUrl.solve

  return buildHtml(tdiv):
    label(class = "label", `for` = ProblemFormId):
      text "問題のURL"
    tdiv(class = "field has-addons"):
      tdiv(class = "control"):
        input(class = "input", `type` = "text", id = ProblemFormId)
      tdiv(class = "control"):
        button(class = "button is-primary", onclick = solveAndWrite):
          text "解探索"
