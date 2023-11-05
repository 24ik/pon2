## This module implements the select frame.
##

{.experimental: "strictDefs".}

import std/[sugar]
import karax/[karax, kbase, karaxdsl, vdom]
import ../../../corepkg/[misc]
import ../../../simulatorpkg/[simulator]

const SelectedClass = kstring"button is-selected is-primary"

proc selectFrame*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the select frame.
  let
    editButtonClass =
      if simulator.mode == IzumiyaSimulatorMode.Edit: SelectedClass
      else: kstring"button"
    playButtonClass =
      if simulator.mode == Play: SelectedClass else: kstring"button"
    replayButtonClass =
      if simulator.mode == Replay: SelectedClass else: kstring"button"

    tsuButtonClass =
      if simulator.rule == Tsu: SelectedClass
      else: kstring"button"
    waterButtonClass =
      if simulator.rule == Water: SelectedClass
      else: kstring"button"

    regularButtonClass =
      if simulator.kind == Regular: SelectedClass else: kstring"button"
    nazoButtonClass =
      if simulator.kind == IzumiyaSimulatorKind.Nazo: SelectedClass
      else: kstring"button"

  result = buildHtml(tdiv):
    tdiv(class = "buttons has-addons mb-0"):
      button(class = editButtonClass,
             onclick = () => (simulator.mode = IzumiyaSimulatorMode.Edit)):
        span(class = "icon"):
          italic(class = "fa-solid fa-pen-to-square")
      button(class = playButtonClass,
             onclick = () => (simulator.mode = Play)):
        span(class = "icon"):
          italic(class = "fa-solid fa-gamepad")
      button(class = replayButtonClass,
             onclick = () => (simulator.mode = Replay)):
        span(class = "icon"):
          italic(class = "fa-solid fa-film")
    tdiv(class = "buttons has-addons mb-0"):
      button(class = tsuButtonClass, onclick = () => (simulator.rule = Tsu)):
        text "通"
      button(class = waterButtonClass,
             onclick = () => (simulator.rule = Water)):
        text "水中"
    tdiv(class = "buttons has-addons"):
      button(class = regularButtonClass,
             onclick = () => (simulator.kind = Regular)):
        text "とこ"
      button(class = nazoButtonClass,
             onclick = () => (simulator.kind = IzumiyaSimulatorKind.Nazo)):
        text "なぞ"
