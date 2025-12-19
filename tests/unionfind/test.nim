{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[unionfind]

block:
  var unionFind = UnionFind.init 6
  unionFind.merge 0, 1
  unionFind.merge 2, 3
  unionFind.merge 2, 4

  check unionFind.root(0) in [0, 1]
  check unionFind.root(1) in [0, 1]
  check unionFind.root(2) in [2, 3, 4]
  check unionFind.root(3) in [2, 3, 4]
  check unionFind.root(4) in [2, 3, 4]
  check unionFind.root(5) == 5

  check unionFind.connected(0, 1)
  check not unionFind.connected(1, 2)
  check unionFind.connected(3, 4)
  check not unionFind.connected(0, 5)
  check not unionFind.connected(4, 5)
