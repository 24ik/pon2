## This module implements the requirement node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, strformat, sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ../../../../apppkg/[simulator]
import ../../../../corepkg/[misc]
import ../../../../nazopuyopkg/[nazopuyo]

const
  KindSelectIdPrefix = "pon2-req-kind"
  ColorSelectIdPrefix = "pon2-req-color"
  NumberSelectIdPrefix = "pon2-req-number"

proc getSelectedKindIndex(id: kstring): int {.importjs:
  &"document.getElementById('{KindSelectIdPrefix}' + (#)).selectedIndex".}
  ## Returns the index of select form for requirement kind.

proc getSelectedColorIndex(id: kstring): int {.importjs:
  &"document.getElementById('{ColorSelectIdPrefix}' + (#)).selectedIndex".}
  ## Returns the index of select form for requirement color.

proc getSelectedNumberIndex(id: kstring): int {.importjs:
  &"document.getElementById('{NumberSelectIdPrefix}' + (#)).selectedIndex".}
  ## Returns the index of select form for requirement number.

func initKindHandler(simulator: var Simulator, id: string): () -> void =
  ## Returns the handler for the kind.
  # NOTE: cannot inline due to lazy evaluation
  () => (simulator.requirementKind =
    id.kstring.getSelectedKindIndex.RequirementKind)

func initColorHandler(simulator: var Simulator, id: string): () -> void =
  ## Returns the handler for the kind.
  # NOTE: cannot inline due to lazy evaluation
  () => (simulator.requirementColor =
    id.kstring.getSelectedColorIndex.RequirementColor)

func initNumberHandler(simulator: var Simulator, id: string): () -> void =
  ## Returns the handler for the kind.
  # NOTE: cannot inline due to lazy evaluation
  () => (simulator.requirementNumber =
    id.kstring.getSelectedNumberIndex.RequirementNumber)

proc initRequirementNode*(simulator: var Simulator, displayMode = false,
                          id = ""): VNode {.inline.} =
  ## Returns the requirement node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  if simulator.kind == Regular:
    return buildHtml(text "　")

  if displayMode or simulator.mode != Edit:
    return buildHtml(bold):
      text $simulator.requirement

  result = buildHtml(tdiv):
    tdiv(class = "block mb-1"):
      tdiv(class = "select"):
        select(id = kstring &"{KindSelectIdPrefix}{id}",
               onclick = simulator.initKindHandler(id)):
          for kind in RequirementKind:
            option(selected = kind == simulator.requirement.kind):
              text $kind
    tdiv(class = "block"):
      if simulator.requirement.kind in ColorKinds:
        button(class = "button is-static px-2"):
          text "c ="
        tdiv(class = "select"):
          select(id = kstring &"{ColorSelectIdPrefix}{id}",
                 onclick = simulator.initColorHandler(id)):
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
          select(id = kstring &"{NumberSelectIdPrefix}{id}",
                 onclick = simulator.initNumberHandler(id)):
            for num in RequirementNumber.low..RequirementNumber.high:
              option(selected = num == simulator.requirement.number.get):
                text $num
