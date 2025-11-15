{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sets, unittest]
import ../../src/pon2/private/[critbits]

block: # toCritBitTree
  let arr = ["a", "ab", "abc", "ab", "bc", "bd"]
  check arr.toCritBitTree.items.toSeq.toHashSet == arr.toHashSet

  let arr2 = {"a": 0, "b": 1, "c": 2}
  check arr2.toCritBitTree.pairs.toSeq.toHashSet == arr2.toHashSet
