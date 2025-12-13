{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sets, unittest]
import ../../src/pon2/private/[critbits]

block: # toCritBitTree
  let items = ["a", "ab", "abc", "ab", "bc", "bd"]
  check items.toCritBitTree.items.toSeq.toHashSet == items.toHashSet

  let items2 = {"a": 0, "b": 1, "c": 2}
  check items2.toCritBitTree.pairs.toSeq.toHashSet == items2.toHashSet
