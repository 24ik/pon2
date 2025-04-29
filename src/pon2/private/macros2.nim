## This module implements macros.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[macros, sugar]
import ./[strutils2]

export macros

# ------------------------------------------------
# Replace
# ref: https://github.com/status-im/nim-stew/blob/master/stew/staticfor.nim
# ------------------------------------------------
# 
func replaced*(node, before, after: NimNode): NimNode {.inline.} =
  ## Returns the nim node with `before` replaced by `after`.
  case node.kind
  of nnkIdent, nnkSym:
    if node.eqIdent before: after else: node
  of nnkEmpty, nnkLiterals:
    node
  else:
    let rTree = newNimNode(node.kind, lineInfoFrom = node)
    for child in node:
      rTree.add child.replaced(before, after)

    rTree

func replace*(node: var NimNode, before, after: NimNode) {.inline.} =
  ## Replaces `before` by `after` in the node.
  node = node.replaced(before, after)

# ------------------------------------------------
# Expand
# ------------------------------------------------

macro defineExpand*(
    macroIdentSuffix: untyped, expandSuffixes: varargs[untyped]
): untyped =
  ## Defines expand macro.
  # identifiers
  let
    identsAndBodyIdent = "identsAndBody".ident
    bodyIdent = "body".ident
    identsIdent = "idents".ident
    stmtsIdent = "stmts".ident

  # macro parameters
  let formalParams = nnkFormalParams.newNimNode
  formalParams.add "untyped".ident
  formalParams.add nnkIdentDefs.newTree(
    identsAndBodyIdent,
    nnkBracketExpr.newTree("varargs".ident, "untyped".ident),
    newEmptyNode(),
  )

  # macro body
  let
    suffixes = collect:
      for suffix in expandSuffixes:
        suffix.strVal
    cmnt =
      """
Runs in sequence with the body (the last argument) changed to the specified
identifiers (the rest arguments) with the suffix """ &
      suffixes.join(", ") &
      ".\nUnderscore in the body is replaced by the index of the suffix."
    macroBody = newStmtList cmnt.newCommentStmtNode
  macroBody.add quote do:
    let
      `bodyIdent` = `identsAndBodyIdent`[^1]
      `identsIdent` = `identsAndBodyIdent`[0 ..^ 2]
      `stmtsIdent` = nnkStmtList.newNimNode `bodyIdent`
  for suffixIdx, suffix in suffixes:
    let expandedBodyIdent = ("body" & suffix).ident

    macroBody.add quote do:
      var `expandedBodyIdent` = `bodyIdent`.replaced("_".ident, `suffixIdx`.newLit)

    let idIdent = "id".ident
    macroBody.add nnkForStmt.newTree(
      idIdent,
      identsIdent,
      quote do:
        `expandedBodyIdent`.replace `idIdent`, (`idIdent`.strVal & `suffix`).ident
      ,
    )

    macroBody.add "add".newCall(stmtsIdent, expandedBodyIdent)

  nnkMacroDef.newTree(
    ("expand" & macroIdentSuffix.strVal).ident,
    newEmptyNode(),
    newEmptyNode(),
    formalParams,
    newEmptyNode(),
    newEmptyNode(),
    macroBody,
  )
