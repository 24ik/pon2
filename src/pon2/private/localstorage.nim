## This module implements a local storage.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import karax/[localstorage]
import ./[dom]
import ../[utils]

export utils

type LocalStorageType* = object ## Local storage. This type has no no real data.

const LocalStorage* = LocalStorageType()

proc pathPrefixAdded(key: string): cstring {.inline, noinit.} =
  ## Returns the key with the path prefix added.
  "{window.location.pathname}-{key}".fmt.cstring

proc contains*(localStorage: LocalStorageType, key: string): bool {.inline, noinit.} =
  key.pathPrefixAdded.hasItem

proc `[]`*(
    localStorage: LocalStorageType, key: string
): Pon2Result[cstring] {.inline, noinit.} =
  let key2 = key.pathPrefixAdded
  if key2.hasItem:
    ok key2.getItem
  else:
    err "key not found: {key}".fmt

proc `[]=`*(
    localStorage: LocalStorageType, key: string, val: cstring
) {.inline, noinit.} =
  key.pathPrefixAdded.setItem val

proc del*(localStorage: LocalStorageType, key: string) {.inline, noinit.} =
  ## Deletes the key.
  ## If the key is not contained in the local storage, does nothing.
  key.pathPrefixAdded.removeItem
