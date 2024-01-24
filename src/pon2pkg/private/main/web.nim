## This module implements auxiliary things for the web main file.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils, strutils, sugar, uri]
import karax/[karax, karaxdsl, vdom]
import ../[misc]
import ../app/web/[webworker]
import ../../apppkg/[editorpermuter, simulator]
import ../../corepkg/[environment, misc, pair, position]
import ../../nazopuyopkg/[nazopuyo, permute, solve]

# ------------------------------------------------
# Web - Worker
# ------------------------------------------------

proc workerTask*(args: seq[string]): tuple[returnCode: WorkerReturnCode,
                                           messages: seq[string]] =
  ## Worker's task.
  # NOTE: cannot inline due to the type of `assignWebWorker` argument
  if args.len == 0:
    result.returnCode = Failure
    result.messages = @["No arguments."]
    return

  let args2 = args[1..^1]
  case args[0]
  of $Solve:
    if args2.len == 1:
      result.returnCode = Success
      args2[0].parseUri.parseNazoPuyos.nazoPuyos.flattenAnd:
        result.messages = nazoPuyo.solve.mapIt it.toUriQuery Izumiya
    else:
      result.returnCode = Failure
      result.messages = @["Caught invalid number of arguments: " & $args]
  of $Permute:
    if args2.len >= 3:
      let fixMoves =
        if args2.len == 3: newSeq[Positive](0)
        else: args2[3..^1].mapIt it.parseSomeInt[:Positive]

      result.returnCode = Success
      args2[0].parseUri.parseNazoPuyos.nazoPuyos.flattenAnd:
        let permuteRes = collect:
          for (pairs, answer) in nazoPuyo.permute(
              fixMoves, args2[1].parseBool, args2[2].parseBool):
            @[pairs.toUriQuery Izumiya, answer.toUriQuery Izumiya]
        result.messages = permuteRes.concat
    else:
      result.returnCode = Failure
      result.messages = @["Caught invalid number of arguments: " & $args]
  else:
    result.returnCode = Failure
    result.messages = @["Caught invalid task: " & args[0]]

# ------------------------------------------------
# Web - Main
# ------------------------------------------------

proc initEditorPermuterNode*(
    routerData: RouterData, pageInitialized: var bool,
    globalEditorPermuter: var EditorPermuter): VNode {.inline.} =
  ## Returns the editor&permuter node.
  if pageInitialized:
    return globalEditorPermuter.initEditorPermuterNode

  pageInitialized = true
  let query =
    if routerData.queryString == cstring"": ""
    else: ($routerData.queryString)[1..^1]

  var uri = initUri()
  uri.scheme = "https"
  uri.hostname = $Izumiya
  uri.path = "/pon2/playground/index.html"
  uri.query = query

  try:
    let parseRes = uri.parseNazoPuyos
    parseRes.nazoPuyos.flattenAnd:
      globalEditorPermuter =
        if parseRes.positions.isSome:
          nazoPuyo.initEditorPermuter(parseRes.positions.get, parseRes.mode,
                                      parseRes.editor)
        else:
          nazoPuyo.initEditorPermuter(parseRes.mode, parseRes.editor)
  except ValueError:
    try:
      let parseRes = uri.parseEnvironments
      parseRes.environments.flattenAnd:
        globalEditorPermuter =
          if parseRes.positions.isSome:
            environment.initEditorPermuter(parseRes.positions.get,
                                          parseRes.mode, parseRes.editor)
          else:
            environment.initEditorPermuter(parseRes.mode, parseRes.editor)
    except ValueError:
      return buildHtml(tdiv):
        text "URL形式エラー"

  result = globalEditorPermuter.initEditorPermuterNode
