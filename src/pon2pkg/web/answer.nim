## This module implements the answer frame.
##

import options
import strformat
import sugar

import karax / [karax, karaxdsl, vdom]
import puyo_simulator

import ../manager

proc answerFrame*(manager: var Manager): VNode {.inline.} =
  ## Returns the answer frame.
  let answerSimulatorFrame =
    manager.answerSimulator[].makePuyoSimulatorAnswerDom(setKeyHandler = false, wrapSection = false)
  return buildHtml(tdiv):
    tdiv(class = "block"):
      nav(class = "pagination", role = "navigation", aria-label = "pagination"):
        button(class = "button pagination-link", onclick = () => manager.prevAnswer):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-step")
        button(class = "button pagination-link is-static"):
          if manager.answers.get.len == 0:
            text "0 / 0"
          else:
            text &"{manager.answerIdx.succ} / {manager.answers.get.len}"
        button(class = "button pagination-link", onclick = () => manager.nextAnswer):
          span(class = "icon"):
            italic(class = "fa-solid fa-forward-step")
    if manager.answers.get.len > 0:
      tdiv(class = "block"):
        answerSimulatorFrame
