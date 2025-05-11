{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[deques2]

block: # init, toDeque2, mpairs
  check Deque[string].init.len == 0

  {.push warning[Uninit]: off.}
  check [1, 2].toDeque2 == [1, 2].toDeque
  {.pop.}

  block: # mpairs
    var deque = [0, 1, 2, 3, 4].toDeque2
    for idx, val in deque.mpairs:
      if idx mod 2 == 0:
        val.inc 10

    check deque == [10, 1, 12, 3, 14].toDeque2
