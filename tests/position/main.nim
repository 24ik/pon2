{.experimental: "strictDefs".}

import std/[unittest]
import ../../src/pon2pkg/core/[position {.all.}]

proc main* =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # initPosition
  block:
    check initPosition(5, Left) == Left5

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # axisColumn, childColumn, childDirection
  block:
    check Right2.axisColumn == 2
    check Right2.childColumn == 3
    check Right2.childDirection == Right

  # ------------------------------------------------
  # Move
  # ------------------------------------------------

  # movedRight, movedLeft, moveRight, moveLeft
  block:
    for (pos, answer) in [(Right2, Right3), (Left5, Left5)]:
      check pos.movedRight == answer

      var pos2 = pos
      pos2.moveRight
      check pos2 == answer

    for (pos, answer) in [(Down3, Down2), (Up0, Up0)]:
      check pos.movedLeft == answer

      var pos2 = pos
      pos2.moveLeft
      check pos2 == answer

  # ------------------------------------------------
  # Rotate
  # ------------------------------------------------

  # rotatedRight, rotatedLeft, rotateRight, rotateLeft
  block:
    for (pos, answer) in [(Left4, Up4), (Up5, Right4)]:
      check pos.rotatedRight == answer

      var pos2 = pos
      pos2.rotateRight
      check pos2 == answer

    for (pos, answer) in [(Down4, Right4), (Up0, Left1)]:
      check pos.rotatedLeft == answer

      var pos2 = pos
      pos2.rotateLeft
      check pos2 == answer
