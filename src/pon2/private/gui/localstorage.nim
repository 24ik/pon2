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
  import std/[jsconsole, json, jsonutils, sugar]
  import ../../[utils]
  import ../../private/[localstorage, strutils]

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

  proc solvedEntryIndices*(
      localStorage: GrimoireLocalStorageType
  ): Pon2Result[set[int16]] =
    ## Returns the solved entry indices.
    let valResult = LocalStorage[GrimoirePrefix & SolvedKey]
    if valResult.isErr:
      return ok set[int16]({})

    try:
      {.push warning[Uninit]: off.}
      return ok ($valResult.unsafeValue).parseJson.jsonTo set[int16]
      {.pop.}
    except Exception as ex:
      return err "cannot get solved entry indices\n" & ex.msg

  proc `solvedEntryIndices=`*(
      localStorage: GrimoireLocalStorageType, entryIndices: set[int16]
  ) =
    ## Sets the solved entry indices.
    try:
      var str {.noinit.}: string
      str.toUgly entryIndices.toJson

      LocalStorage[GrimoirePrefix & SolvedKey] = str.cstring
    except Exception as ex:
      console.error ex

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
