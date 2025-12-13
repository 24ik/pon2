{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, unittest]
import ../../src/pon2/private/[deques]

block: # init
  check Deque[string].init.len == 0

block: # toDeques
  let items = @[1, 2, 3]
  check items.toDeque.items.toSeq == items

block: # insert, del
  var deque = [0, 1, 2, 3, 4].toDeque
  deque.del 1
  check deque == [0, 2, 3, 4].toDeque
  deque.insert 10, 1
  check deque == [0, 10, 2, 3, 4].toDeque

block: # mpairs
  var deque = [0, 1, 2, 3, 4].toDeque
  for index, val in deque.mpairs:
    if index mod 2 == 0:
      val += 10

  check deque == [10, 1, 12, 3, 14].toDeque
