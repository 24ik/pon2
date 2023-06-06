## This module implements GUI state.
##

type
  Mode* {.pure.} = enum
    ## GUI editor mode.
    EDIT
    PLAY
    RECORD

  Focus* {.pure.} = enum
    ## Which area is focused in the :code:`EDIT` mode.
    FIELD
    PAIRS
    REQUIREMENT

  SimulatorState* {.pure.} = enum
    ## Field state in the simulator.
    MOVING
    BEFORE_DISAPPEAR
    BEFORE_DROP

  RecordState* {.pure.} = enum
    ## State in the :code:`RECORD` mode.
    EMPTY
    WRITING
    READY
