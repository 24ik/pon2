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
  func assign*[T](tgt: var T, src: T) {.inline, noinit.} =
    ## Assigns the source to the target.
    tgt = src
else:
  proc humaneTypeName(typedescNode: NimNode): string =
    var t = getType(typedescNode)[1]
    if t.kind != nnkBracketExpr:
      let tImpl = t.getImpl
      if tImpl != nil and tImpl.kind notin {nnkEmpty, nnkNilLit}:
        t = tImpl

    repr(t)

  func assign*[T](tgt: var seq[T], src: openArray[T]) {.gcsafe, inline, noinit.}
    ## Assigns the source to the target.
  func assign*[T](tgt: var openArray[T], src: openArray[T]) {.gcsafe, inline, noinit.}
    ## Assigns the source to the target.
  func assign*[T](tgt: var T, src: T) {.gcsafe, inline, noinit.}
    ## Assigns the source to the target.

  func assignImpl[T](tgt: var openArray[T], src: openArray[T]) {.inline, noinit.} =
    ## Assigns the source to the target.
    mixin assign
    when supportsCopyMem(T):
      if tgt.len > 0:
        moveMem(addr tgt[0], unsafeAddr src[0], sizeof(tgt[0]) * tgt.len)
    else:
      for i in 0 ..< tgt.len:
        assign(tgt[i], src[i])

  func assignImpl[T: object or tuple](tgt: var T, src: T) {.inline, noinit.} =
    ## Assigns the source to the target.
    mixin assign

    for t, s in fields(tgt, src):
      when supportsCopyMem(type s) and sizeof(s) <= sizeof(int) * 2:
        t = s # Shortcut
      else:
        assign(t, s)

  func assign*[T](tgt: var openArray[T], src: openArray[T]) {.inline, noinit.} =
    ## Assigns the source to the target.
    mixin assign

    if tgt.len != src.len:
      raiseAssert "Target and source lengths don't match: " & $tgt.len & " vs " &
        $src.len

    when nimvm:
      for i in 0 ..< tgt.len:
        tgt[i] = src[i]
    else:
      assignImpl(tgt, src)

  func assign*[T](tgt: var seq[T], src: openArray[T]) {.inline, noinit.} =
    ## Assigns the source to the target.
    mixin assign

    tgt.setLen(src.len)

    when nimvm:
      for i in 0 ..< tgt.len:
        tgt[i] = src[i]
    else:
      assignImpl(tgt.toOpenArray(0, tgt.high), src)

  func assign*(tgt: var string, src: string) {.inline, noinit.} =
    ## Assigns the source to the target.
    tgt.setLen(src.len)
    when nimvm:
      for i in 0 ..< tgt.len:
        tgt[i] = src[i]
    else:
      assignImpl(tgt.toOpenArrayByte(0, tgt.high), src.toOpenArrayByte(0, tgt.high))

  func assign*[T](tgt: var T, src: T) {.inline, noinit.} =
    ## Assigns the source to the target.
    mixin assign
    when nimvm:
      tgt = src
    else:
      when supportsCopyMem(T):
        when sizeof(src) <= sizeof(int):
          tgt = src
        else:
          moveMem(addr tgt, unsafeAddr src, sizeof(tgt))
      elif T is object | tuple:
        when compiles(tgt.assignImpl src):
          tgt.assignImpl src
        else:
          tgt = src
      elif T is seq:
        assign(tgt, src.toOpenArray(0, src.high))
      elif T is ref:
        tgt = src
      elif compiles(distinctBase(tgt)):
        assign(distinctBase tgt, distinctBase src)
      else:
        error "Assignment of the type " & humaneTypeName(T) & " is not supported"
