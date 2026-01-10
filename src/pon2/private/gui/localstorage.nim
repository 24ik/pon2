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
  import std/[asyncjs, jsconsole, json, jsonutils, sequtils, sugar]
  import ../../[utils]
  import ../../private/[bitops, localstorage, math, staticfor, strutils, zlib]

  export utils

  type GrimoireLocalStorageType* = object
    ## Local storage for the grimoire. This type has no real data.

  const
    GrimoireLocalStorage* = GrimoireLocalStorageType()

    GrimoirePrefix = "grimoire-"

  # ------------------------------------------------
  # Grimoire
  # ------------------------------------------------

  const
    SolvedKey = "solved"
    SelectedKey = "selected"
    ImportedKey = "imported"

  proc jsonToSet(str: string): Pon2Result[set[int16]] =
    ## Returns the set converted from the json string.
    try:
      {.push warning[Uninit]: off.}
      return ok str.parseJson.jsonTo set[int16]
      {.pop.}
    except:
      return err "cannot convert to set\n" & getCurrentExceptionMsg()

  proc solvedEntryIndices*(
      localStorage: GrimoireLocalStorageType
  ): Pon2Result[set[int16]] =
    ## Returns the solved entry indices.
    let valResult = LocalStorage[GrimoirePrefix & SolvedKey]
    if valResult.isErr:
      return ok set[int16]({})

    ($valResult.unsafeValue).jsonToSet.context "cannot get solved entry indices"

  proc `solvedEntryIndices=`*(
      localStorage: GrimoireLocalStorageType, entryIndices: set[int16]
  ) =
    ## Sets the solved entry indices.
    try:
      var str {.noinit.}: string
      str.toUgly entryIndices.toJson

      LocalStorage[GrimoirePrefix & SolvedKey] = str.cstring
    except:
      console.error getCurrentExceptionMsg().cstring

  proc selectedEntryIndex*(localStorage: GrimoireLocalStorageType): Pon2Result[int16] =
    ## Returns the selected entry index.
    ## If not set, returns `-1`.
    let valResult = LocalStorage[GrimoirePrefix & SelectedKey]
    if valResult.isErr:
      return ok -1'i16

    ($valResult.unsafeValue).parseInt.map((index: int) => index.int16).context "cannot get selected entry index"

  proc `selectedEntryIndex=`*(
      localStorage: GrimoireLocalStorageType, entryIndex: int16
  ) =
    ## Sets the selected entry index.
    LocalStorage[GrimoirePrefix & SelectedKey] = ($entryIndex).cstring

  # ------------------------------------------------
  # Grimoire - Export
  # ------------------------------------------------

  func toBytes(indices: set[int16]): seq[byte] =
    ## Returns the bytes converted from the indices.
    if indices.card == 0:
      return @[]

    let indicesSeq = indices.toSeq
    var bytes = 0.byte.repeat (indicesSeq[^1] div 8) + 1
    for index in indices:
      let (arrayIndex, bitIndex) = index.divmod 8
      bytes[arrayIndex].setBit bitIndex

    bytes

  proc exportedStr*(
      localStorage: GrimoireLocalStorageType
  ): Future[Pon2Result[string]] {.async.} =
    ## Returns a string to export grimoire local storage.
    let indicesResult = localStorage.solvedEntryIndices
    if indicesResult.isOk:
      let compressedResult = await indicesResult.unsafeValue.toBytes.zlibCompressed
      if compressedResult.isOk:
        return Pon2Result[string].ok compressedResult.unsafeValue
      else:
        return Pon2Result[string].err "cannot export\n" & compressedResult.error
    else:
      return Pon2Result[string].err "cannot export\n" & indicesResult.error

  # ------------------------------------------------
  # Grimoire - Import
  # ------------------------------------------------

  func toIndices(bytes: seq[byte]): set[int16] =
    ## Returns the indices converted from the bytes.
    var indices = set[int16]({})
    for index, val in bytes:
      if val == 0:
        continue

      let baseVal = index * 8
      staticFor(bitIndex, 0 ..< 8):
        if val.getBit bitIndex:
          indices.incl (baseVal + bitIndex).int16

    indices

  proc importStr*(
      localStorage: GrimoireLocalStorageType, str: string
  ): Future[Pon2Result[void]] {.async.} =
    ## Imports a string to update the grimoire local storage.
    let bytesResult = await str.zlibDecompressed
    if bytesResult.isOk:
      localStorage.solvedEntryIndices = bytesResult.unsafeValue.toIndices
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
