## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}

import std/[dom, strutils]
import karax/[kbase]
import ../[simulator]
import ../../corepkg/[cell]

func cellImageSrc*(cell: Cell): kstring {.inline.} =
  ## Returns the image src.
  kstring case cell
  of Cell.None: "./assets/puyo/none.png"
  of Cell.Hard: "./assets/puyo/hard.png"
  of Cell.Garbage: "./assets/puyo/garbage.png"
  of Cell.Red: "./assets/puyo/red.png"
  of Cell.Green: "./assets/puyo/green.png"
  of Cell.Blue: "./assets/puyo/blue.png"
  of Cell.Yellow: "./assets/puyo/yellow.png"
  of Cell.Purple: "./assets/puyo/purple.png"

func toColorCode*(color: tuple[red: byte, green: byte, blue: byte]): kstring
                 {.inline.} =
  ## Returns the color code string with prefix "#".
  kstring "#" & color.red.toHex(2) & color.green.toHex(2) & color.blue.toHex(2)

func toKeyEvent*(event: KeyboardEvent): KeyEvent {.inline.} =
  ## Converts KeyboardEvent to the KeyEvent.
  initKeyEvent($event.code, event.shiftKey, event.ctrlKey, event.altKey,
               event.metaKey)
