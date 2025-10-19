{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[paths2]

block: # srcPath, splitPath2, joinPath2
  let
    src = srcPath()
    (head, tail) = src.splitPath2
  check tail == "test.nim".Path
  check head.splitPath2.tail == "paths2".Path

  check head.joinPath(tail) == src
