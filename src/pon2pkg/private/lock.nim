## This module implements the web locks and atomic types.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[macros, sugar]
import karax/[kbase]
import nuuid

type Atomic2*[T] = object
  ## Atomic data structure.
  data: T
  lockName: kstring

# ------------------------------------------------
# Lock
# ------------------------------------------------

proc acquireThen(lockName: kstring, bodyProc: () -> void) {.importjs:
  "navigator.locks.request(#, #)".} ## Runs the procedure with the lock.

template withLock*(lockName: kstring, body: untyped): untyped =
  ## Runs the body with the lock.
  lockName.acquireThen () => body

# ------------------------------------------------
# Atomic
# ------------------------------------------------

func toAtomic2*[T](data: T, lockName = generateUUID()): Atomic2[T] {.inline.} =
  ## Returns a new atomic.
  result.data = data
  result.lockName = lockName.kstring

proc `[]`*[T](atomic: Atomic2[T]): T {.inline.} =
  ## Returns the data.
  var res: T
  atomic.lockName.withLock:
    res = atomic.data # HACK: directly set to `result` raises error
  result = res

proc `[]=`*[T](atomic: var Atomic2[T], data: T) {.inline.} =
  ## Sets the data.
  atomic.lockName.withLock:
    atomic.data = data

macro `~>`*[T](atomic: var Atomic2[T], body: untyped): untyped =
  ## Atomic processing.
  runnableExamples:
    var atomic = 5.toAtomic2
    atomic~>dec() # cannot omit parens
    atomic~>inc(3) # cannot omit parens
    assert atomic[] == 7

  expectKind body, nnkCall

  var body2 = body.copy
  body2.insert 1, quote do: `atomic`.data

  result = quote do:
    `atomic`.lockName.withLock:
      `body2`
