## This module implements union-find trees.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar]

type
  UnionFindNode* = int ## Union-find node.

  UnionFind* = object ## Union-find tree.
    parents: seq[UnionFindNode]
    subtreeSizes: seq[int]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type UnionFind, size: int): T {.inline, noinit.} =
  let parents = collect:
    for i in 0 ..< size:
      i.UnionFindNode

  UnionFind(parents: parents, subtreeSizes: 1.repeat size)

# ------------------------------------------------
# Operation
# ------------------------------------------------

func root*(self: var UnionFind, node: UnionFindNode): UnionFindNode {.inline, noinit.} =
  ## Returns the root of the tree containing the node.
  ## Path compression is also performed.
  if self.parents[node] == node:
    return node

  # path compression
  self.parents[node] = self.parents[self.parents[node]]

  self.root self.parents[node]

func merge*(self: var UnionFind, node1, node2: UnionFindNode) {.inline, noinit.} =
  ## Merges the subtree containing `node1` with the subtree containing `node2`.
  ## Merging strategy is union-by-size.
  let
    root1 = self.root node1
    root2 = self.root node2
  if root1 == root2:
    return

  # union-by-size merge
  let
    bigRoot: UnionFindNode
    smallRoot: UnionFindNode
  if self.subtreeSizes[root1] >= self.subtreeSizes[root2]:
    bigRoot = root1
    smallRoot = root2
  else:
    bigRoot = root2
    smallRoot = root1
  self.subtreeSizes[bigRoot].inc self.subtreeSizes[smallRoot]
  self.parents[smallRoot] = bigRoot

func connected*(
    self: var UnionFind, node1, node2: UnionFindNode
): bool {.inline, noinit.} =
  ## Returns `true` if `node1` and `node2` are connected.
  self.root(node1) == self.root(node2)
