## This module implements assets handling.
##

{.experimental: "strictDefs".}

import std/[httpclient, logging, net, options, appdirs, dirs, files, paths,
            strformat]
import nigui
import ../../core/[cell]

type Assets* = object
  cellImages*: array[Cell, Image]
  cellImageSize*: tuple[height: Natural, width: Natural]

const FilePaths: array[Cell, Path] = [
  Path "none.png", Path "hard.png", Path "garbage.png", Path "red.png",
  Path "green.png", Path "blue.png", Path "yellow.png", Path "purple.png"]

let logger = newConsoleLogger(lvlNotice, verboseFmtStr)

proc initAssets*(timeoutSec = 180): Assets =
  ## Returns the assets.
  ##
  ## This function automatically downloads the missing assets.
  ## Downloading requires the compile option `-d:ssl`.
  let client = newHttpClient(timeout = timeoutSec * 1000)

  let assetsDir = getDataDir() / "puyo-simulator".Path / "assets".Path /
    "puyo-small".Path
  assetsDir.createDir

  result.cellImages[None] = newImage() # dummy to remove warning
  for cell, path in FilePaths:
    let fullPath = assetsDir / path
    if not fullPath.fileExists:
      logger.log lvlInfo, "Downloading ", path.string, " ..."

      {.push warning[Uninit]:off.}
      client.downloadFile(
        "https://github.com/izumiya-keisuke/puyo-simulator/raw/main/" &
        &"assets/puyo-small/{path.string}",
        fullPath.string)
      {.pop.}

    let img = newImage()
    img.loadFromFile fullPath.string
    result.cellImages[cell] = img

  result.cellImageSize.width = result.cellImages[None].width
  result.cellImageSize.height = result.cellImages[None].height
