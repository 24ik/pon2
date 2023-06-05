## This module implements the entry point for making a web page.
##

include karax/prelude

import ./view/message
import ./view/simulator
import ./view/solve

proc makeWebPageCore: VNode =
  ## Returns the full page.
  buildHtml(tdiv):
    tdiv(class = "columns"):
      tdiv(class = "column"):
        section(class = "section"):
          h1(class = "title"):
            text "ソルバー"

          solverField()
        section(class = "section"):
          messageTable()
      tdiv(class = "column"):
        simulatorFrame()

proc makeWebPage* =
  ## Makes the full web page.
  makeWebPageCore.setRenderer
