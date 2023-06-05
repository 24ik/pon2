## This module implements common constants.
##

import os

const
  AppName = "pon2"
  DataDir* = (
    when defined(windows): "APPDATA".getEnv getHomeDir() / "AppData" / "Roaming"
    elif defined(macos): getHomeDir() / "Application Support"
    else: "XDG_DATA_HOME".getEnv getHomeDir() / ".local" / "share"
  ) / AppName
  ConfigDir* = (
    when defined(windows): "APPDATA".getEnv getHomeDir() / "AppData" / "Roaming"
    elif defined(macos): getHomeDir() / "Application Support"
    else: "XDG_CONFIG_HOME".getEnv getHomeDir() / ".config"
  ) / AppName
