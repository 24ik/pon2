import stew/[staticfor]

export staticfor

template staticFor*[E: enum](
    idx: untyped{nkIdent}, slice: static Slice[E], body: untyped
): untyped =
  ## Unrolled `for` loop over the given slice.
  staticFor(idx2, slice.a.ord .. slice.b.ord):
    const `idx` = idx2.E
    body

template staticFor*(
    idx: untyped{nkIdent}, enumType: typedesc[enum], body: untyped
): untyped =
  ## Unrolled `for` loop over the all value in the given enum type.
  staticFor(idx, enumType.low .. enumType.high):
    body
