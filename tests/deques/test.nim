{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, unittest]
import ../../src/pon2/private/[deques]

block: # init
  check Deque[string].init.len == 0

block: # toDeques
  let arr = @[1, 2, 3]
  check arr.toDeque.items.toSeq == arr

block: # insert, del
  var deq = [0, 1, 2, 3, 4].toDeque
  deq.del 1
  check deq == [0, 2, 3, 4].toDeque
  deq.insert 10, 1
  check deq == [0, 10, 2, 3, 4].toDeque

block: # mpairs
  var deque = [0, 1, 2, 3, 4].toDeque
  for idx, val in deque.mpairs:
    if idx mod 2 == 0:
      val.inc 10

  check deque == [10, 1, 12, 3, 14].toDeque
