## This module implements assets handling.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[appdirs, dirs, files, paths, strformat, syncio]
import nigui
import puppy
import ../../../../core/[cell]

type
  AssetsObj = object
    cellImages*: array[Cell, Image]
    cellImageSize*: tuple[height: Natural, width: Natural]

  Assets* = ref AssetsObj

const FilePaths: array[Cell, Path] = [
  Path "none.png",
  Path "hard.png",
  Path "garbage.png",
  Path "red.png",
  Path "green.png",
  Path "blue.png",
  Path "yellow.png",
  Path "purple.png",
]

proc newAssets*(timeoutSec = 180): Assets =
  ## Returns the assets.
  ## This function automatically downloads the missing assets.
  result.new

  let assetsDir = getDataDir() / "pon2".Path / "assets".Path / "puyo-small".Path
  assetsDir.createDir

  result.cellImages[None] = newImage() # HACK: dummy to suppress warning
  for cell, path in FilePaths:
    let fullPath = assetsDir / path
    if not fullPath.fileExists:
      ($fullPath).writeFile fetch &"https://github.com/24ik/pon2/raw/main/assets/puyo-small/{path.string}"

    let img = newImage()
    img.loadFromFile fullPath.string
    result.cellImages[cell] = img

  result.cellImageSize.width = result.cellImages[None].width
  result.cellImageSize.height = result.cellImages[None].height
