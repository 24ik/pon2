## This module implements various algorithms.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}
{.push raises: [].}

import std/[algorithm, sequtils]

export algorithm except product

func product*[T](seqs: openArray[seq[T]]): seq[seq[T]] {.inline, noinit.} =
  ## Returns a cartesian product.
  case seqs.len
  of 0:
    @[newSeq[T]()]
  of 1:
    seqs[0].mapIt @[it]
  else:
    algorithm.product seqs
