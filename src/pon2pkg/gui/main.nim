## This module implements the entry point of the GUI application.
##

import options
import tables

import docopt
import nazopuyo_core
import nigui
import puyo_core
import tiny_sqlite

import ./config
import ./resource
import ./state
import ./window
import ../core/db

# ------------------------------------------------
# Entry Point
# ------------------------------------------------

proc runGui(nazo: Nazo, positions: Positions, play: bool) {.inline.} =
  ## Runs the GUI applicaton.
  app.init

  let cfgRef = new Config
  cfgRef[] = loadConfig()

  let resource = loadResource()
  if resource.isNone:
    echo "画像ファイルが読み込めません．"
    return
  let resourceRef = new Resource
  resourceRef[] = resource.get

  let db = connectDb()
  if db.isNone:
    echo "データベースを開けません．"
    return
  let dbRef = new DbConn
  dbRef[] = db.get

  try:
    let window = nazo.newWindow(positions, if play: PLAY else: Mode.EDIT, cfgRef, resourceRef, dbRef)
    window.show

    app.run
  finally:
    dbRef[].close

proc runGui*(args: Table[string, Value]) {.inline.} =
  ## Runs the GUI applicaton.
  case args["<url>"].kind
  of vkNone:
    makeEmptyNazo().runGui newSeq[Option[Position]](), false
  of vkStr:
    let nazoPositions = ($args["<url>"]).toNazoPositions true
    if nazoPositions.isNone:
      echo "正しくない形式のURLが入力されました．"
      return

    nazoPositions.get.nazo.runGui nazoPositions.get.positions, true
  else:
    doAssert false
