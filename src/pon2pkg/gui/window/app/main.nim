## This module implements the constructor of the application window.
##

import nazopuyo_core
import puyo_core
import tiny_sqlite

import ./handler
import ./state
import ./window
import ../resource
import ../../setting/main

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc newWindow*(
  nazo: Nazo, positions: Positions, mode: Mode, setting: ref Setting, resource: ref Resource, db: ref DbConn
): AppWindow {.inline.} =
  ## Returns a new window.
  result = newWindowView(nazo, positions, mode, setting, resource, db)
  result.setHandlers
