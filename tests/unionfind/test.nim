{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[unionfind]

block:
  var uf = UnionFind.init 6
  uf.merge 0, 1
  uf.merge 2, 3
  uf.merge 2, 4

  check uf.root(0) in [0, 1]
  check uf.root(1) in [0, 1]
  check uf.root(2) in [2, 3, 4]
  check uf.root(3) in [2, 3, 4]
  check uf.root(4) in [2, 3, 4]
  check uf.root(5) == 5

  check uf.connected(0, 1)
  check not uf.connected(1, 2)
  check uf.connected(3, 4)
  check not uf.connected(0, 5)
  check not uf.connected(4, 5)
