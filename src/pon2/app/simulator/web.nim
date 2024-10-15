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
  ]

# ------------------------------------------------
# Node
# ------------------------------------------------

const ReqIdPrefix = "pon2-simulator-req-"

proc newSimulatorNode(self: Simulator, id: string): VNode {.inline.} =
  ## Returns the node without the external section.
  buildHtml(tdiv):
    tdiv(class = "block"):
      self.newRequirementNode(id = &"{ReqIdPrefix}{id}")
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
          if self.mode in {PlayEditor, Edit}:
            tdiv(class = "block"):
              self.newSelectNode
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

proc newSimulatorNode*(self: Simulator, wrapSection = true, id = ""): VNode {.inline.} =
  ## Returns the simulator node.
  let node = self.newSimulatorNode id

  if wrapSection:
    result = buildHtml(section(class = "section")):
      node
  else:
    result = node
