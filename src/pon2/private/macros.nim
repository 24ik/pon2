## This module implements macros.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[macros]

export macros

# ------------------------------------------------
# Replace
# ref: https://github.com/status-im/nim-stew/blob/master/stew/staticfor.nim
# ------------------------------------------------
# 
func replaced*(node, before, after: NimNode): NimNode {.inline, noinit.} =
  ## Returns the nim node with `before` replaced by `after`.
  case node.kind
  of nnkIdent, nnkSym:
    if node.eqIdent before: after else: node
  of nnkEmpty, nnkLiterals:
    node
  else:
    let resultTree = node.kind.newNimNode node
    for child in node:
      resultTree.add child.replaced(before, after)

    resultTree

func replace*(node: var NimNode, before, after: NimNode) {.inline, noinit.} =
  ## Replaces `before` by `after` in the node.
  node = node.replaced(before, after)
