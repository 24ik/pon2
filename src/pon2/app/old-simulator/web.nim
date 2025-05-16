## This module implements Puyo Puyo simulators for web.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import karax/[karaxdsl, vdom]
import ../[simulator]
import
  ../../private/app/simulator/web/[
    controller,
    field,
    immediatepairs,
    messages,
    operating as operatingModule,
    pairs as pairsModule,
    palette,
    requirement,
    select,
    share,
  ]

# ------------------------------------------------
# Node
# ------------------------------------------------

const
  ReqIdPrefix = "pon2-simulator-req-"
  ShareIdPrefix = "pon2-simulator-share-"

proc newSimulatorNode(self: Simulator, id: string, isAnswer: bool): VNode {.inline.} =
  ## Returns the node without the external section.
  let shareId = &"{ShareIdPrefix}{id}"

  result = buildHtml(tdiv):
    if self.kind == Nazo:
      tdiv(class = "block"):
        self.newRequirementNode &"{ReqIdPrefix}{id}"
    tdiv(class = "block"):
      tdiv(class = "columns is-mobile is-variable is-1"):
        tdiv(class = "column is-narrow"):
          if self.mode != Edit:
            tdiv(class = "block"):
              self.newOperatingNode
          tdiv(class = "block"):
            self.newFieldNode
          if self.mode != Edit:
            tdiv(class = "block"):
              self.newMessagesNode
          if not isAnswer and self.mode != Play:
            tdiv(class = "block"):
              self.newSelectNode
          tdiv(class = "block"):
            self.newShareNode(shareId, isAnswer)
        if self.mode != Edit:
          tdiv(class = "column is-narrow"):
            tdiv(class = "block"):
              self.newImmediatePairsNode
        tdiv(class = "column is-narrow"):
          tdiv(class = "block"):
            self.newControllerNode
          if self.mode == Edit:
            tdiv(class = "block"):
              self.newPaletteNode
          tdiv(class = "block"):
            self.newPairsNode
    self.newDisplayNode shareId

proc newSimulatorNode*(
    self: Simulator, wrapSection = true, id = "", isAnswer = false
): VNode {.inline.} =
  ## Returns the simulator node.
  let node = self.newSimulatorNode(id, isAnswer)

  if wrapSection:
    result = buildHtml(section(class = "section")):
      node
  else:
    result = node
