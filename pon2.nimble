# Package

version       = "0.5.0"
author        = "Keisuke Izumiya"
description   = "Nazo Puyo Tool"
license       = "Apache-2.0 OR MPL-2.0"

srcDir        = "src"
installExt    = @["nim", "png"]
bin           = @["pon2"]


# Dependencies

requires "nim ^= 2.0.0"

requires "docopt ^= 0.7.0"
requires "nigui ^= 0.2.7"
requires "tiny_sqlite ^= 0.2.0"
requires "yaml ^= 1.1.0"
requires "https://github.com/karaxnim/karax#2371ea3"
requires "https://github.com/izumiya-keisuke/nazopuyo-core.git ^= 0.3.0"
requires "https://github.com/izumiya-keisuke/puyo-core.git ^= 0.4.0"


# Tasks

import os
import strformat

task test, "Test":
  let mainFile = "./src/pon2.nim".unixToNativePath
  try:
    exec &"nim doc --project --index {mainFile}"
  except OSError: # HACK: now `nim doc` can generates htmldocs but raises error (due to docopt's bug)
    discard
  rmDir "./src/htmldocs".unixToNativePath

  exec "nimble -y build"

  exec "testament all"