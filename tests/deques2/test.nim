{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[deques2]

block: # init, toDeque2
  check Deque[string].init.len == 0

  {.push warning[Uninit]: off.}
  check [1, 2].toDeque2 == [1, 2].toDeque
  {.pop.}
