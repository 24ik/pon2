import stew/[staticfor]

export staticfor

template staticFor*[E: enum](
    index: untyped{nkIdent}, slice: static Slice[E], body: untyped
): untyped =
  ## Unrolled `for` loop over the given slice.
  staticFor(index2, slice.a.ord .. slice.b.ord):
    const `index` = index2.E
    body

template staticFor*(
    index: untyped{nkIdent}, enumType: typedesc[enum], body: untyped
): untyped =
  ## Unrolled `for` loop over the all value in the given enum type.
  staticFor(index, enumType.low .. enumType.high):
    body
