{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[ unittest]
import ../../src/pon2/private/[staticcase]

block: # staticCase
  func nextPow2(x: static int): int =
    staticCase:
      case x
      of 0, 1:
        1
      of 2:
        2
      of 3, 4:
        4
      of 5 .. 8:
        8
      elif 9 <= x and x < 17:
        16
      else:
        -1

  check 0.nextPow2 == 1
  check 1.nextPow2 == 1
  check 2.nextPow2 == 2
  check 3.nextPow2 == 4
  check 7.nextPow2 == 8
  check 13.nextPow2 == 16
  check 18.nextPow2 == -1
