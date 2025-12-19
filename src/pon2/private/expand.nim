## This module implements expand macros.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import ./[macros, strutils]

# NOTE: macros that is defined by `defineExpand` have `macros.add` procedure and
# `defineExpand`'s caller uses them, so we need to export `macros`.
export macros

macro defineExpand*(
    macroIdentSuffix: untyped, expandSuffixes: varargs[untyped]
): untyped =
  ## Defines expand macro.
  runnableExamples:
    defineExpand("Example", "Foo", "Bar")
    # This defines the following macro:
    #[
    macro expandExample(identsAndBody: varargs[untyped]): untyped =
      ## Runs in sequence with the body (the last argument) changed to the specified
      ## identifiers (the rest arguments) with the suffix Foo, Bar.
      ## Underscore in the body is replaced by the index of the suffix.
      let
        body = identsAndBody[^1]
        idents = identsAndBody[0 ..^ 2]
        stmts = nnkStmtList.newNimNode body

      var bodyFoo = body.replaced("_".ident, 0.newLit)
      for id in idents:
        bodyFoo.replace id, (id.strVal & "Foo").ident

      add(stmts, bodyFoo)

      var bodyBar = body.replaced("_".ident, 1.newLit)
      for id in idents:
        bodyBar.replace id, (id.strVal & "Bar").ident

      add(stmts, bodyBar)

      stmts
    ]#

    let
      xFoo = 10
      xBar = 20
      yFoo = 100
      yBar = 200

    expandExample x, y:
      assert x == (_ + 1) * 10
      assert y == (_ + 1) * 100

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
    comment =
      "Runs in sequence with the body (the last argument) changed to the specified\nidentifiers (the rest arguments) with the suffix " &
      suffixes.join(", ") &
      ".\nUnderscore in the body is replaced by the index of the suffix."
    macroBody = newStmtList comment.newCommentStmtNode
  macroBody.add quote do:
    let
      `bodyIdent` = `identsAndBodyIdent`[^1]
      `identsIdent` = `identsAndBodyIdent`[0 ..^ 2]
      `stmtsIdent` = nnkStmtList.newNimNode `bodyIdent`
  for suffixIndex, suffix in suffixes:
    let expandedBodyIdent = ("body" & suffix).ident

    macroBody.add quote do:
      var `expandedBodyIdent` = `bodyIdent`.replaced("_".ident, `suffixIndex`.newLit)

    let idIdent = "id".ident
    macroBody.add nnkForStmt.newTree(
      idIdent,
      identsIdent,
      quote do:
        `expandedBodyIdent`.replace `idIdent`, (`idIdent`.strVal & `suffix`).ident
      ,
    )

    macroBody.add "add".newCall(stmtsIdent, expandedBodyIdent)

  macroBody.add stmtsIdent

  nnkMacroDef.newTree(
    ("expand" & macroIdentSuffix.strVal).ident,
    newEmptyNode(),
    newEmptyNode(),
    formalParams,
    newEmptyNode(),
    newEmptyNode(),
    macroBody,
  )
