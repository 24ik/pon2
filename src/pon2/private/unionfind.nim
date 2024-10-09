## This module implements union-find trees.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar]

type
  UnionFindNode* = Natural ## Union-find node.

  UnionFind* = object ## Union-find tree.
    parents: seq[UnionFindNode]
    subtreeSizes: seq[Positive]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initUnionFind*(size: Natural): UnionFind {.inline.} =
  ## Returns a new union-find tree.
  let parents = collect:
    for i in 0 ..< size:
      UnionFindNode i

  {.push warning[ProveInit]: off.}
  {.push warning[UnsafeDefault]: off.}
  {.push warning[UnsafeSetLen]: off.}
  result = UnionFind(parents: parents, subtreeSizes: 1.Positive.repeat size)
  {.pop.}
  {.pop.}
  {.pop.}

# ------------------------------------------------
# Operation
# ------------------------------------------------

func getRoot*(self: var UnionFind, node: UnionFindNode): UnionFindNode {.inline.} =
  ## Returns the root of the tree containing the node.
  ## Path compression is also performed.
  if self.parents[node] == node:
    return node

  # path compression
  self.parents[node] = self.parents[self.parents[node]]

  result = self.getRoot self.parents[node]

func merge*(self: var UnionFind, node1, node2: UnionFindNode) {.inline.} =
  ## Merges the tree containing `node1` and the one containing `node2`
  ## using a union-by-size strategy.
  let
    root1 = self.getRoot node1
    root2 = self.getRoot node2
  if root1 == root2:
    return

  # union-by-size merge
  let (big, small) =
    if self.subtreeSizes[root1] >= self.subtreeSizes[root2]:
      (root1, root2)
    else:
      (root2, root1)
  self.subtreeSizes[big].inc self.subtreeSizes[small]
  self.parents[small] = big

func sameGroup*(self: var UnionFind, node1, node2: UnionFindNode): bool {.inline.} =
  ## Returns `true` if `node1` and `node2` are contained in the same tree.
  self.getRoot(node1) == self.getRoot(node2)

when isMainModule:
  echo "a"
