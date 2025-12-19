## This modules implements assignments.
##
# ref: https://github.com/status-im/nim-stew/blob/master/stew/assign2.nim
# ref: https://github.com/status-im/nim-stew/blob/master/stew/shims/macros.nim

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when not defined(js):
  import std/[typetraits]
  import ./[macros]

when defined(js):
  func assign*[T](dst: var T, src: T) {.inline, noinit.} =
    ## Assigns the source to the destination.
    dst = src
else:
  proc humaneTypeName(typedescNode: NimNode): string =
    var t = getType(typedescNode)[1]
    if t.kind != nnkBracketExpr:
      let tImpl = t.getImpl
      if tImpl != nil and tImpl.kind notin {nnkEmpty, nnkNilLit}:
        t = tImpl

    repr(t)

  func assign*[T](dst: var seq[T], src: openArray[T]) {.gcsafe, inline, noinit.}
    ## Assigns the source to the destination.
  func assign*[T](dst: var openArray[T], src: openArray[T]) {.gcsafe, inline, noinit.}
    ## Assigns the source to the destination.
  func assign*[T](dst: var T, src: T) {.gcsafe, inline, noinit.}
    ## Assigns the source to the destination.

  func assignImpl[T](dst: var openArray[T], src: openArray[T]) {.inline, noinit.} =
    ## Assigns the source to the destination.
    mixin assign
    when supportsCopyMem(T):
      if dst.len > 0:
        moveMem(addr dst[0], unsafeAddr src[0], sizeof(dst[0]) * dst.len)
    else:
      for i in 0 ..< dst.len:
        assign(dst[i], src[i])

  func assignImpl[T: object or tuple](dst: var T, src: T) {.inline, noinit.} =
    ## Assigns the source to the destination.
    mixin assign

    for t, s in fields(dst, src):
      when supportsCopyMem(type s) and sizeof(s) <= sizeof(int) * 2:
        t = s # Shortcut
      else:
        assign(t, s)

  func assign*[T](dst: var openArray[T], src: openArray[T]) {.inline, noinit.} =
    ## Assigns the source to the destination.
    mixin assign

    if dst.len != src.len:
      raiseAssert "Destination and source lengths don't match: " & $dst.len & " vs " &
        $src.len

    when nimvm:
      for i in 0 ..< dst.len:
        dst[i] = src[i]
    else:
      assignImpl(dst, src)

  func assign*[T](dst: var seq[T], src: openArray[T]) {.inline, noinit.} =
    ## Assigns the source to the destination.
    mixin assign

    dst.setLen(src.len)

    when nimvm:
      for i in 0 ..< dst.len:
        dst[i] = src[i]
    else:
      assignImpl(dst.toOpenArray(0, dst.high), src)

  func assign*(dst: var string, src: string) {.inline, noinit.} =
    ## Assigns the source to the destination.
    dst.setLen(src.len)
    when nimvm:
      for i in 0 ..< dst.len:
        dst[i] = src[i]
    else:
      assignImpl(dst.toOpenArrayByte(0, dst.high), src.toOpenArrayByte(0, dst.high))

  func assign*[T](dst: var T, src: T) {.inline, noinit.} =
    ## Assigns the source to the destination.
    mixin assign
    when nimvm:
      dst = src
    else:
      when not compiles(static(T.sizeof)):
        dst = src
      elif supportsCopyMem(T):
        when sizeof(src) <= sizeof(int):
          dst = src
        else:
          moveMem(addr dst, unsafeAddr src, sizeof(dst))
      elif T is object | tuple:
        when compiles(dst.assignImpl src):
          dst.assignImpl src
        else:
          dst = src
      elif T is seq:
        assign(dst, src.toOpenArray(0, src.high))
      elif T is ref:
        dst = src
      elif compiles(distinctBase(dst)):
        assign(distinctBase dst, distinctBase src)
      else:
        error "Assignment of the type " & humaneTypeName(T) & " is not supported"
