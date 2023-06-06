## This module implements the solver view.
##

import options
import sequtils
import std/asyncjs

include karax/prelude

import ./message
import ./simulator
import ../../core/solve

const ProblemFormId = "question-form"

proc solveAndWrite =
  ## Solves the nazo puyo and writes solutions to the messages.
  # NOTE: this function should be async, but Karax does not allow async event handler.
  # (Nim's async function returns Future[T], but the return type of Karax's event handlers need to be void.)
  let url = ProblemFormId.getVNodeById.getInputText
  if url == kstring"":
    return

  let solutions = ($url).solve
  if solutions.isNone:
    messages = @[kstring"URL形式エラー"]
    return

  simulatorUrls = solutions.get.mapIt it.kstring
  simulatorIdx = 0
  messages = simulatorUrls

proc solverField*: VNode =
  ## Returns the solver view.
  buildHtml(tdiv):
    label(class = "label", `for` = ProblemFormId):
      text "問題のURL"
    tdiv(class = "field has-addons"):
      tdiv(class = "control"):
        input(
          class = "input",
          `type` = "text",
          placeholder = "https://ishikawapuyo.net/simu/pn.html?301301j02m0_4121__u03",
          id = ProblemFormId)
      tdiv(class = "control"):
        button(class = "button is-primary", onclick = solveAndWrite):
          text "解探索"
