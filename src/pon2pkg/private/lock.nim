## This module implements the web locks.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[kbase]

proc acquireThen(lockName: kstring, bodyProc: () -> void) {.importjs:
  "navigator.locks.request(#, #)".} ## Runs the procedure with the lock.

template withLock*(lockName: kstring, body: untyped): untyped =
  ## Runs the body with the lock.
  lockName.acquireThen () => body
