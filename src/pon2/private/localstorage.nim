## This module implements a local storage.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import karax/[localstorage]
import ../[utils]

export utils

type LocalStorage* = object ## Local storage.

var localStorage* = LocalStorage()

proc pathPrefixAdded(key: string): cstring {.inline, noinit.} =
  ## Returns the key with the path prefix added.
  "{window.location.pathname}-{key}".fmt.cstring

proc contains*(self: LocalStorage, key: string): bool {.inline, noinit.} =
  key.pathPrefixAdded.hasItem

proc `[]`*(self: LocalStorage, key: string): Pon2Result[cstring] {.inline, noinit.} =
  let key2 = key.pathPrefixAdded
  if key2.hasItem:
    ok key2.getItem
  else:
    err "key not found: {key}".fmt

proc `[]=`*(self: var LocalStorage, key: string, val: cstring) {.inline, noinit.} =
  key.pathPrefixAdded.setItem val

proc del*(self: var LocalStorage, key: string) {.inline, noinit.} =
  ## Deletes the key.
  ## If the key is not contained in the local storage, does nothing.
  key.pathPrefixAdded.removeItem
