{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}
{.push raises: [].}

import std/[unittest]
import ../../src/pon2/private/[paths]

block: # srcPath, splitPath, joinPath
  let
    src = srcPath()
    (head, tail) = src.splitPath
  check tail == "test.nim".Path
  check head.splitPath.tail == "paths".Path

  check head.joinPath(tail) == src
