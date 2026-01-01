## This module implements suffix arrays.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar]
import ./[algorithm, assign, strutils]

type SuffixArray* = object ## Suffix array.
  suffixIndices: seq[int]
  joinedStr: string
  originalIndices: seq[int]

const Sep = '\0'

func init*(T: type SuffixArray, strs: openArray[string]): T {.inline, noinit.} =
  # joinedStr, originalIndices
  var
    joinedStr = ""
    originalIndices = newSeq[int]()
  for strIndex, str in strs:
    let strSep = str & Sep

    joinedStr &= strSep
    originalIndices &= strIndex.repeat strSep.len

  # suffixIndices (doubling)
  let joinedStrLen = joinedStr.len
  var
    suffixIndices = collect:
      for index in 0 ..< joinedStrLen:
        index
    ords = joinedStr.mapIt it.ord
    size = 1
  while size < joinedStrLen:
    # sort indices
    proc cmpFunc(index1, index2: int): int =
      if ords[index1] == ords[index2]:
        let
          ord1 =
            if index1 + size < joinedStrLen:
              ords[index1 + size]
            else:
              -1
          ord2 =
            if index2 + size < joinedStrLen:
              ords[index2 + size]
            else:
              -1

        cmp(ord1, ord2)
      else:
        cmp(ords[index1], ords[index2])

    suffixIndices.sort cmpFunc

    # update ords
    var newOrds = newSeq[int](joinedStrLen)
    newOrds[suffixIndices[0]].assign 0
    for index in 1 ..< joinedStrLen:
      newOrds[suffixIndices[index]].assign newOrds[suffixIndices[index - 1]] +
        (cmpFunc(suffixIndices[index - 1], suffixIndices[index]) < 0).int
    ords.assign newOrds

    if ords[suffixIndices[^1]] == joinedStrLen - 1:
      break

    size *= 2

  SuffixArray(
    suffixIndices: suffixIndices, joinedStr: joinedStr, originalIndices: originalIndices
  )

func cmp(txt: string, startIndex: int, query: string): int {.inline, noinit.} =
  ## Compare function for `findAll`.
  let
    txtLen = txt.len
    queryLen = query.len

  for index in 0 ..< min(txtLen - startIndex, queryLen):
    let
      txtOrd = txt[startIndex + index].ord
      queryOrd = query[index].ord
    if txtOrd != queryOrd:
      return txtOrd - queryOrd

  if queryLen <= txtLen - startIndex: 0 else: -1

func findAll*(self: SuffixArray, query: string): set[int16] {.inline, noinit.} =
  ## Returns the all indices of the strings that have the query as their substrings.
  if query.len == 0:
    return set[int16]({})

  let joinedStrLen = self.joinedStr.len

  # begin index
  let beginIndex = block:
    var
      low = 0
      high = joinedStrLen
    while low < high:
      let mid = (low + high) div 2
      if cmp(self.joinedStr, self.suffixIndices[mid], query) < 0:
        low.assign mid + 1
      else:
        high.assign mid

    low

  # end index
  let endIndex = block:
    var
      low = beginIndex
      high = joinedStrLen
    while low < high:
      let mid = (low + high) div 2
      if cmp(self.joinedStr, self.suffixIndices[mid], query) <= 0:
        low.assign mid + 1
      else:
        high.assign mid

    low

  var indices = set[int16]({})
  for index in beginIndex ..< endIndex:
    indices.incl self.originalIndices[self.suffixIndices[index]].int16

  indices
