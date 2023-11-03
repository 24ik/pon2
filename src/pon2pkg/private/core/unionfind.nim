## This module implements union-find structures.
##

{.experimental: "strictDefs".}

import std/[sequtils, sugar]

type
  UnionFindNode* = Natural

  UnionFind* = object
    ## Union-find structure.
    parents: seq[UnionFindNode]
    sizes: seq[Natural]

using
  mSelf: var UnionFind

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initUnionFind*(size: Natural): UnionFind {.inline.} =
  ## Union-find constructor.
  result.parents = collect:
    for i in 0..<size:
      UnionFindNode i

  result.sizes = 0.Natural.repeat size

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

func merge*(mSelf; node1, node2: UnionFindNode) {.inline.} =
  ## Merges the tree containing `node1` and the one containing `node2`
  ## using a union-by-size strategy.
  let
    root1 = mSelf.getRoot node1
    root2 = mSelf.getRoot node2
  if root1 == root2:
    return

  # union-by-size merge
  let rootBig, rootSmall: UnionFindNode
  if mSelf.sizes[root1] > mSelf.sizes[root2]:
    rootBig = root1
    rootSmall = root2
  else:
    rootBig = root2
    rootSmall = root1
  mSelf.sizes[rootBig].inc mSelf.sizes[rootSmall]
  mSelf.parents[rootSmall] = rootBig

func isSame*(mSelf; node1, node2: UnionFindNode): bool {.inline.} =
  ## Returns `true` if `node1` and `node2` are contained in the same tree.
  mSelf.getRoot(node1) == mSelf.getRoot(node2)
