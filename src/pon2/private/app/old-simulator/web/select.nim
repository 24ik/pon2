## This module implements the select node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ../../../../app/[simulator]
import ../../../../core/[rule]

const
  SelectedClass = kstring"button is-selected is-primary"
  NotSelectedClass = kstring"button"

proc newSelectNode*(simulator: Simulator): VNode {.inline.} =
  ## Returns the select node.
  let
    playEditorButtonClass =
      if simulator.mode == PlayEditor: SelectedClass else: NotSelectedClass
    editButtonClass = if simulator.mode == Edit: SelectedClass else: NotSelectedClass
    viewButtonClass = if simulator.mode == View: SelectedClass else: NotSelectedClass

    tsuButtonClass = if simulator.rule == Tsu: SelectedClass else: NotSelectedClass
    waterButtonClass = if simulator.rule == Water: SelectedClass else: NotSelectedClass

  result = buildHtml(tdiv):
    tdiv(class = "buttons has-addons mb-1"):
      button(
        class = playEditorButtonClass, onclick = () => (simulator.mode = PlayEditor)
      ):
        span(class = "icon"):
          italic(class = "fa-solid fa-gamepad")
      button(class = editButtonClass, onclick = () => (simulator.mode = Edit)):
        span(class = "icon"):
          italic(class = "fa-solid fa-pen-to-square")
      button(class = viewButtonClass, onclick = () => (simulator.mode = View)):
        span(class = "icon"):
          italic(class = "fa-solid fa-circle-play")
    if simulator.mode == Edit:
      tdiv(class = "buttons has-addons"):
        button(class = tsuButtonClass, onclick = () => (simulator.rule = Tsu)):
          text "通"
        button(class = waterButtonClass, onclick = () => (simulator.rule = Water)):
          text "水中"
