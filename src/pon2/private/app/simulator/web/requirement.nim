## This module implements the requirement node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ../../../../app/[nazopuyo, simulator]
import ../../../../core/[requirement]

const
  KindSelectIdPrefix = "pon2-simulator-req-kind-"
  ColorSelectIdPrefix = "pon2-simulator-req-color-"
  NumberSelectIdPrefix = "pon2-simulator-req-number-"

proc getSelectedKindIndex(
  id: kstring
): int {.
  importjs: &"document.getElementById('{KindSelectIdPrefix}' + (#)).selectedIndex"
.} ## Returns the index of select form for requirement kind.

proc getSelectedColorIndex(
  id: kstring
): int {.
  importjs: &"document.getElementById('{ColorSelectIdPrefix}' + (#)).selectedIndex"
.} ## Returns the index of select form for requirement color.

proc getSelectedNumberIndex(
  id: kstring
): int {.
  importjs: &"document.getElementById('{NumberSelectIdPrefix}' + (#)).selectedIndex"
.} ## Returns the index of select form for requirement number.

func newKindHandler(simulator: ref Simulator, id: string): () -> void =
  ## Returns the handler for the kind.
  # NOTE: cannot inline due to lazy evaluation
  () => (simulator[].requirementKind = id.kstring.getSelectedKindIndex.RequirementKind)

func newColorHandler(simulator: ref Simulator, id: string): () -> void =
  ## Returns the handler for the kind.
  # NOTE: cannot inline due to lazy evaluation
  () =>
    (simulator[].requirementColor = id.kstring.getSelectedColorIndex.RequirementColor)

func newNumberHandler(simulator: ref Simulator, id: string): () -> void =
  ## Returns the handler for the kind.
  # NOTE: cannot inline due to lazy evaluation
  () =>
    (
      simulator[].requirementNumber =
        id.kstring.getSelectedNumberIndex.RequirementNumber
    )

proc newRequirementNode*(
    simulator: ref Simulator, displayMode = false, id: string
): VNode {.inline.} =
  ## Returns the requirement node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  if simulator[].kind == Regular:
    return buildHtml(tdiv):
      discard

  let req = simulator[].nazoPuyoWrap.get:
    wrappedNazoPuyo.requirement

  if displayMode or simulator[].mode != Edit:
    return buildHtml(bold):
      text $req

  result = buildHtml(tdiv):
    tdiv(class = "block mb-1"):
      tdiv(class = "select"):
        select(
          id = kstring &"{KindSelectIdPrefix}{id}",
          onchange = simulator.newKindHandler(id),
        ):
          for kind in RequirementKind:
            option(selected = kind == req.kind):
              text $kind
    tdiv(class = "block"):
      if req.kind in ColorKinds:
        button(class = "button is-static px-2"):
          text "c ="
        tdiv(class = "select"):
          select(
            id = kstring &"{ColorSelectIdPrefix}{id}",
            onchange = simulator.newColorHandler(id),
          ):
            option(selected = req.color == RequirementColor.All):
              text "全"
            for color in RequirementColor.All.succ .. RequirementColor.high:
              option(selected = color == req.color):
                text $color
      if req.kind in NumberKinds:
        button(class = "button is-static px-2"):
          text "n ="
        tdiv(class = "select"):
          select(
            id = kstring &"{NumberSelectIdPrefix}{id}",
            onchange = simulator.newNumberHandler(id),
          ):
            for num in RequirementNumber.low .. RequirementNumber.high:
              option(selected = num == req.number):
                text $num
