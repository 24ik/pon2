## This module implements the requirement frame.
##

{.experimental: "strictDefs".}

import std/[options, strformat, sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ../../../corepkg/[misc]
import ../../../nazopuyopkg/[nazopuyo]
import ../../../simulatorpkg/[simulator]

const
  KindSelectIdPrefix = "puyo-simulator-select-req-kind"
  ColorSelectIdPrefix = "puyo-simulator-select-req-color"
  NumberSelectIdPrefix = "puyo-simulator-select-req-number"

proc getSelectedKindIndex(idx: int): int {.importjs:
  &"document.getElementById('{KindSelectIdPrefix}' + (#)).selectedIndex".}
  ## Returns the index of select form for requirement kind.

proc getSelectedColorIndex(idx: int): int {.importjs:
  &"document.getElementById('{ColorSelectIdPrefix}' + (#)).selectedIndex".}
  ## Returns the index of select form for requirement color.

proc getSelectedNumberIndex(idx: int): int {.importjs:
  &"document.getElementById('{NumberSelectIdPrefix}' + (#)).selectedIndex".}
  ## Returns the index of select form for requirement number.

func initKindHandler(simulator: var Simulator, idx: int): () -> void =
  ## Returns the handler for the kind.
  () => (simulator.requirementKind = idx.getSelectedKindIndex.RequirementKind)

func initColorHandler(simulator: var Simulator, idx: int): () -> void =
  ## Returns the handler for the kind.
  () => (simulator.requirementColor =
    idx.getSelectedColorIndex.RequirementColor)

func initNumberHandler(simulator: var Simulator, idx: int): () -> void =
  ## Returns the handler for the kind.
  () => (simulator.requirementNumber =
    idx.getSelectedNumberIndex.RequirementNumber)

proc requirementFrame*(simulator: var Simulator, simple = false, idx = 0): VNode
                      {.inline.} =
  ## Returns the requirement frame.
  if simulator.kind == Regular:
    return buildHtml(text "　")

  if simple or simulator.mode in {Play, Replay}:
    return buildHtml(bold):
      text $simulator.requirement

  result = buildHtml(tdiv):
    tdiv(class = "block mb-1"):
      tdiv(class = "select"):
        select(id = kstring &"{KindSelectIdPrefix}{idx}",
               onclick = simulator.initKindHandler(idx)):
          for kind in RequirementKind:
            option(selected = kind == simulator.requirement.kind):
              text $kind
    tdiv(class = "block"):
      if simulator.requirement.kind in ColorKinds:
        button(class = "button is-static px-2"):
          text "c ="
        tdiv(class = "select"):
          select(id = kstring &"{ColorSelectIdPrefix}{idx}",
                 onclick = simulator.initColorHandler(idx)):
            option(selected = simulator.requirement.color.get ==
                RequirementColor.All):
              text "全"
            for color in RequirementColor.All.succ..RequirementColor.high:
              option(selected = color == simulator.requirement.color.get):
                text $color
      if simulator.requirement.kind in NumberKinds:
        button(class = "button is-static px-2"):
          text "n ="
        tdiv(class = "select"):
          select(id = kstring &"{NumberSelectIdPrefix}{idx}",
                 onclick = simulator.initNumberHandler(idx)):
            for num in RequirementNumber.low..RequirementNumber.high:
              option(selected = num == simulator.requirement.number.get):
                text $num
