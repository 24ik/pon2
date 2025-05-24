{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, unittest]
import ../../src/pon2/private/[critbits2]

block: # toCritBitTree2
  let arr = ["a", "ab", "abc", "ab", "bc", "bd"]
  check arr.toCritBitTree.items.toSeq == arr.toCritBitTree2.items.toSeq
