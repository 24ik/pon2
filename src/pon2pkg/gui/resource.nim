## This module implements resources handling.
##

import options
import os

import nigui
import puyo_core

type Resource* = tuple
  ## Resources data.
  cellImages: array[Cell, Image]
  cellImageWidth: int
  cellImageHeight: int

# ------------------------------------------------
# Entry Point
# ------------------------------------------------

proc loadResource*: Option[Resource] =
  ## Returns the resources.
  ## If the loading fails, returns :code:`none(Resource)`.
  const FileNames: array[Cell, string] = [
    "none.png",
    "",
    "garbage.png",
    "red.png",
    "green.png",
    "blue.png",
    "yellow.png",
    "purple.png"]

  let resourceDir= getAppDir() / "resources"

  var resource: Resource
  for cell, fileName in FileNames:
    if fileName == "":
      continue

    let filePath = resourceDir / fileName
    if not filePath.fileExists:
      return

    let img = newImage()
    img.loadFromFile filePath
    resource.cellImages[cell] = img

  resource.cellImageWidth = resource.cellImages[NONE].width
  resource.cellImageHeight = resource.cellImages[NONE].height

  return some resource
