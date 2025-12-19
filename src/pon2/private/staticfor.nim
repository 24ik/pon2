## This module implements static unrolled for-loop.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils]
import stew/[staticfor]
import ./[macros]

template staticFor*[T: Ordinal](
    elemIdent: untyped{nkIdent}, elems: static Slice[T], body: untyped
): untyped =
  ## Unrolled `for` loop over the given slice.
  const ElemOrdSlice = elems.a.ord .. elems.b.ord
  staticFor(elemOrd, ElemOrdSlice):
    const `elemIdent` = elemOrd.T
    body

macro staticFor*(
    elemIdent: untyped{nkIdent}, elems: static openArray[int], body: untyped
): untyped =
  ## Unrolled `for` loop over the given array.
  let stmts = nnkStmtList.newNimNode body
  for elem in elems:
    stmts.add nnkBlockStmt.newTree(
      nnkEmpty.newNimNode, body.replaced(elemIdent, elem.newLit)
    )

  stmts

template staticFor*[T: Ordinal](
    elemIdent: untyped{nkIdent}, elems: static openArray[T], body: untyped
): untyped =
  ## Unrolled `for` loop over the given array.
  const ElemOrds = elems.mapIt it.ord
  staticFor(elemOrd, ElemOrds):
    const `elemIdent` = elemOrd.T
    body

template staticFor*[T: Ordinal](
    elemIdent: untyped{nkIdent}, elems: static set[T], body: untyped
): untyped =
  ## Unrolled `for` loop over the given set.
  const ElemsSeq = elems.toSeq
  staticFor(elemIdent, ElemsSeq, body)

template staticFor*[T: Ordinal](
    elemIdent: untyped{nkIdent}, elemType: typedesc[T], body: untyped
): untyped =
  ## Unrolled `for` loop over the all value in the given enum type.
  const ElemsSlice = elemType.low .. elemType.high
  staticFor(elemIdent, ElemsSlice, body)
