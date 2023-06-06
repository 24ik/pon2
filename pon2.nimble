# Package

version       = "0.2.2"
author        = "Keisuke Izumiya"
description   = "Nazo Puyo Tool"
license       = "Apache-2.0 OR MPL-2.0"

srcDir        = "src"
installExt    = @["nim", "png"]
bin           = @["pon2"]


# Dependencies

requires "nim >= 1.6.12"

requires "docopt >= 0.7.0"
requires "karax >= 1.3.0"
requires "nigui >= 0.2.7"
requires "tiny_sqlite >= 0.2.0"
requires "yaml >= 1.1.0"
requires "https://github.com/izumiya-keisuke/nazopuyo-core.git >= 0.1.1"
requires "https://github.com/izumiya-keisuke/puyo-core.git >= 0.2.1"


# Tasks

import os
import strformat

task test, "Test":
  let mainFile = "./src/pon2.nim".unixToNativePath
  exec &"nim doc --threads:on --project --index {mainFile}"
  rmDir "./src/htmldocs".unixToNativePath

  exec "testament all"