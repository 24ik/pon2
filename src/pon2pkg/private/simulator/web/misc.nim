## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}

import std/[dom, strutils]
import karax/[kbase]
import ../[render]
import ../../../corepkg/[cell]
import ../../../simulatorpkg/[simulator]

func cellImageSrc*(cell: Cell): kstring {.inline.} =
  ## Returns the image src.
  kstring case cell
  of None: "./assets/puyo/none.png"
  of Hard: "./assets/puyo/hard.png"
  of Garbage: "./assets/puyo/garbage.png"
  of Red: "./assets/puyo/red.png"
  of Green: "./assets/puyo/green.png"
  of Blue: "./assets/puyo/blue.png"
  of Yellow: "./assets/puyo/yellow.png"
  of Purple: "./assets/puyo/purple.png"

func toColorCode*(color: Color): kstring {.inline.} =
  ## Converts the color to the color code string with prefix "#".
  kstring join ["#", color.red.toHex(2), color.green.toHex(2),
                color.blue.toHex(2), color.alpha.toHex(2)]

func toKeyEvent*(event: KeyboardEvent): KeyEvent {.inline.} =
  ## Converts KeyboardEvent to the KeyEvent.
  initKeyEvent($event.code, event.shiftKey, event.ctrlKey, event.altKey,
               event.metaKey)
