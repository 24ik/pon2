## This module implements union-find trees.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar]

type
  UnionFindNode* = Natural ## Union-find node.

  UnionFind* = object ## Union-find tree.
    parents: seq[UnionFindNode]
    subtreeSizes: seq[Positive]

using
  self: UnionFind
  mSelf: var UnionFind

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initUnionFind*(size: Natural): UnionFind {.inline.} =
  ## Returns a new union-find tree.
  result.parents = collect:
    for i in 0 ..< size:
      UnionFindNode i

  {.push warning[ProveInit]: off.}
  {.push warning[UnsafeDefault]: off.}
  {.push warning[UnsafeSetLen]: off.}
  result.subtreeSizes = 1.Positive.repeat size
  {.pop.}
  {.pop.}
  {.pop.}

# ------------------------------------------------
# Operation
# ------------------------------------------------

func getRoot*(mSelf; node: UnionFindNode): UnionFindNode {.inline.} =
  ## Returns the root of the tree containing the node.
  ## Path compression is also performed.
  if mSelf.parents[node] == node:
    return node

  # path compression
  mSelf.parents[node] = mSelf.parents[mSelf.parents[node]]

  result = mSelf.getRoot mSelf.parents[node]

func merge*(mSelf; node1: UnionFindNode, node2: UnionFindNode) {.inline.} =
  ## Merges the tree containing `node1` and the one containing `node2`
  ## using a union-by-size strategy.
  let
    root1 = mSelf.getRoot node1
    root2 = mSelf.getRoot node2
  if root1 == root2:
    return

  # union-by-size merge
  let (big, small) =
    if mSelf.subtreeSizes[root1] >= mSelf.subtreeSizes[root2]:
      (root1, root2)
    else:
      (root2, root1)
  mSelf.subtreeSizes[big].inc mSelf.subtreeSizes[small]
  mSelf.parents[small] = big

func sameGroup*(mSelf; node1: UnionFindNode, node2: UnionFindNode): bool {.inline.} =
  ## Returns `true` if `node1` and `node2` are contained in the same tree.
  mSelf.getRoot(node1) == mSelf.getRoot(node2)
