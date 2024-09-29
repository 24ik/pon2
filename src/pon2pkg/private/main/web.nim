## This module implements helper functions for the web main file.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strformat, strutils, uri]
import karax/[karax, karaxdsl, vdom]
import ../[misc, webworker]
import ../app/[solve]
import ../app/gui/web/[webworker]
import ../../app/[gui, marathon, nazopuyo, simulator, solve]
import ../../core/[field, host, nazopuyo, pairposition, puyopuyo, rule]

# ------------------------------------------------
# Web Worker
# ------------------------------------------------

proc workerTask*(
    args: seq[string]
): tuple[returnCode: WorkerReturnCode, messages: seq[string]] =
  ## Worker's task.
  # NOTE: cannot inline due to the type of `assignWebWorker` argument
  if args.len == 0:
    result.returnCode = Failure
    result.messages = @["No arguments."]
    return

  let args2 = args[1 ..^ 1]
  case args[0]
  of $Solve:
    if args2.len == 2:
      result.messages =
        case args2[0].parseRule
        of Tsu:
          parseNode[TsuField](args2[1]).solve.mapIt it.toUriQuery Ik
        of Water:
          parseNode[WaterField](args2[1]).solve.mapIt it.toUriQuery Ik

      result.returnCode = Success
    else:
      result.returnCode = Failure
      result.messages = @["Caught invalid number of arguments: " & $args]
  of $Permute:
    if args2.len == 2:
      result.returnCode = Success

      let nazoPuyoWrap: NazoPuyoWrap
      case args2[1].parseRule
      of Tsu:
        nazoPuyoWrap = parseNazoPuyo[TsuField](args2[0], Ik).initNazoPuyoWrap
      of Water:
        nazoPuyoWrap = parseNazoPuyo[WaterField](args2[0], Ik).initNazoPuyoWrap

      nazoPuyoWrap.get:
        let answers = wrappedNazoPuyo.solve(earlyStopping = true)
        if answers.len == 1:
          result.messages = @[$true, answers[0].toUriQuery Ik]
        else:
          result.messages = @[$false]
    else:
      result.returnCode = Failure
      result.messages = @["Caught invalid number of arguments: " & $args]
  else:
    result.returnCode = Failure
    result.messages = @["Caught invalid task: " & args[0]]

# ------------------------------------------------
# Main - GUI
# ------------------------------------------------

var globalGuiApplication: ref GuiApplication = nil

proc initFooterNode(): VNode {.inline.} =
  ## Returns the footer node.
  buildHtml(footer(class = "footer")):
    tdiv(class = "content has-text-centered"):
      text &"Pon!通 Version {Version}"

proc initMainGuiApplicationNode*(routerData: RouterData): VNode {.inline.} =
  ## Returns the main GUI application node.
  if not globalGuiApplication.isNil:
    return buildHtml(tdiv):
      globalGuiApplication.initGuiApplicationNode
      initFooterNode()

  let query =
    if routerData.queryString == cstring"":
      ""
    else:
      ($routerData.queryString)[1 ..^ 1]

  var uri = initUri()
  uri.scheme = "https"
  uri.hostname = $Ik
  uri.path = "/pon2/"
  uri.query = query

  try:
    let simulator = new Simulator
    simulator[] = uri.parseSimulator

    globalGuiApplication.new
    globalGuiApplication[] = simulator.initGuiApplication

    result = buildHtml(tdiv):
      globalGuiApplication.initGuiApplicationNode
      initFooterNode()
  except ValueError:
    globalGuiApplication = nil
    result = buildHtml(tdiv):
      text "URL形式エラー"

# ------------------------------------------------
# Main - Marathon
# ------------------------------------------------

var globalMarathon: ref Marathon = nil

proc initMainMarathonNode*(): VNode {.inline.} =
  ## Returns the main marathon node.
  if not globalMarathon.isNil:
    return buildHtml(tdiv):
      globalMarathon.initMarathonNode
      initFooterNode()

  globalMarathon.new
  globalMarathon[] = initMarathon()

  result = buildHtml(tdiv):
    globalMarathon.initMarathonNode
    initFooterNode()
