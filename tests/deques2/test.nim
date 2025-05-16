{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[deques2]

block: # init, toDeque2, delete, mpairs
  check Deque[string].init.len == 0

block: # toDeques2
  {.push warning[Uninit]: off.}
  check [1, 2].toDeque2 == [1, 2].toDeque
  {.pop.}

block: # insert, delete
  var deq = [0, 1, 2, 3, 4].toDeque2
  deq.delete 1
  check deq == [0, 2, 3, 4].toDeque2
  deq.insert 10, 1
  check deq == [0, 10, 2, 3, 4].toDeque2

block: # mpairs
  var deque = [0, 1, 2, 3, 4].toDeque2
  for idx, val in deque.mpairs:
    if idx mod 2 == 0:
      val.inc 10

  check deque == [10, 1, 12, 3, 14].toDeque2
