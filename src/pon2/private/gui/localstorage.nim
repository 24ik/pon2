## This module implements the local storage for GUI.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[asyncjs, jsconsole, json, jsonutils, sequtils]
  import ../../[app]
  import ../../private/[bitops, localstorage, math, staticfor, strutils, zlib]

  export app

  type
    StudioLocalStorageType* = object
      ## Local storage for the studio. This type has no real data.

    MarathonLocalStorageType* = object
      ## Local storage for the marathon. This type has no real data.

    GrimoireLocalStorageType* = object
      ## Local storage for the grimoire. This type has no real data.

  const
    StudioLocalStorage* = StudioLocalStorageType()
    MarathonLocalStorage* = MarathonLocalStorageType()
    GrimoireLocalStorage* = GrimoireLocalStorageType()

    StudioPrefix = "studio-"
    MarathonPrefix = "marathon-"
    GrimoirePrefix = "grimoire-"

  # ------------------------------------------------
  # Key Bind
  # ------------------------------------------------

  const KeyBindPatternKey = "keybind"

  proc keyBindPattern*[
      L: StudioLocalStorageType or MarathonLocalStorageType or GrimoireLocalStorageType
  ](localStorage: L): Pon2Result[SimulatorKeyBindPattern] =
    ## Returns the key bind pattern.
    const Prefix =
      when L is StudioLocalStorageType:
        StudioPrefix
      elif L is MarathonLocalStorageType:
        MarathonPrefix
      else:
        GrimoirePrefix

    let valResult = LocalStorage[Prefix & KeyBindPatternKey]
    if valResult.isErr:
      return ok Pon2

    parseOrdinal[SimulatorKeyBindPattern](($valResult.unsafeValue)).context "cannot get key bind pattern"

  proc `keyBindPattern=`*[
      L: StudioLocalStorageType or MarathonLocalStorageType or GrimoireLocalStorageType
  ](localStorage: L, keyBindPattern: SimulatorKeyBindPattern) =
    ## Sets the key bind pattern.
    const Prefix =
      when L is StudioLocalStorageType:
        StudioPrefix
      elif L is MarathonLocalStorageType:
        MarathonPrefix
      else:
        GrimoirePrefix

    LocalStorage[Prefix & KeyBindPatternKey] = ($keyBindPattern.ord).cstring

  # ------------------------------------------------
  # Grimoire
  # ------------------------------------------------

  const
    SolvedKey = "solved"
    ImportedKey = "imported"

  proc jsonToSet(str: string): Pon2Result[set[int16]] =
    ## Returns the set converted from the json string.
    try:
      {.push warning[Uninit]: off.}
      return ok str.parseJson.jsonTo set[int16]
      {.pop.}
    except:
      return err "cannot convert to set\n" & getCurrentExceptionMsg()

  proc solvedEntryIds*(localStorage: GrimoireLocalStorageType): Pon2Result[set[int16]] =
    ## Returns the solved entry IDs.
    let valResult = LocalStorage[GrimoirePrefix & SolvedKey]
    if valResult.isErr:
      return ok set[int16]({})

    ($valResult.unsafeValue).jsonToSet.context "cannot get solved entry IDs"

  proc `solvedEntryIds=`*(
      localStorage: GrimoireLocalStorageType, entryIds: set[int16]
  ) =
    ## Sets the solved entry IDs.
    try:
      var str {.noinit.}: string
      str.toUgly entryIds.toJson

      LocalStorage[GrimoirePrefix & SolvedKey] = str.cstring
    except:
      console.error getCurrentExceptionMsg().cstring

  # ------------------------------------------------
  # Grimoire - Export
  # ------------------------------------------------

  func toBytes(ids: set[int16]): seq[byte] =
    ## Returns the bytes converted from the IDs.
    if ids.card == 0:
      return @[]

    let idsSeq = ids.toSeq
    var bytes = 0.byte.repeat (idsSeq[^1] div 8) + 1
    for id in ids:
      let (arrayIndex, bitIndex) = id.divmod 8
      bytes[arrayIndex].setBit bitIndex

    bytes

  proc exportedStr*(
      localStorage: GrimoireLocalStorageType
  ): Future[Pon2Result[string]] {.async.} =
    ## Returns a string to export grimoire local storage.
    let idsResult = localStorage.solvedEntryIds
    if idsResult.isOk:
      let compressedResult = await idsResult.unsafeValue.toBytes.zlibCompressed
      if compressedResult.isOk:
        return Pon2Result[string].ok compressedResult.unsafeValue
      else:
        return Pon2Result[string].err "cannot export\n" & compressedResult.error
    else:
      return Pon2Result[string].err "cannot export\n" & idsResult.error

  # ------------------------------------------------
  # Grimoire - Import
  # ------------------------------------------------

  func toIds(bytes: seq[byte]): set[int16] =
    ## Returns the IDs converted from the bytes.
    var ids = set[int16]({})
    for index, val in bytes:
      if val == 0:
        continue

      let baseVal = index * 8
      staticFor(bitIndex, 0 ..< 8):
        if val.getBit bitIndex:
          ids.incl (baseVal + bitIndex).int16

    ids

  proc importStr*(
      localStorage: GrimoireLocalStorageType, str: string
  ): Future[Pon2Result[void]] {.async.} =
    ## Imports a string to update the grimoire local storage.
    let bytesResult = await str.zlibDecompressed
    if bytesResult.isOk:
      localStorage.solvedEntryIds = bytesResult.unsafeValue.toIds
      LocalStorage[GrimoirePrefix & ImportedKey] = "1"
      return Pon2Result[void].ok
    else:
      return Pon2Result[void].err "cannot import\n" & bytesResult.error

  proc imported*(localStorage: GrimoireLocalStorageType): bool =
    ## Returns `true` if the local storage is updated by `importStr`.
    (GrimoirePrefix & ImportedKey) in LocalStorage

  proc `imported=`*(localStorage: GrimoireLocalStorageType, imported: bool) =
    ## Sets the import status.
    LocalStorage.del GrimoirePrefix & ImportedKey
