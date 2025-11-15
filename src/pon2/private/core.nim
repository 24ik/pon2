## This module implements private stuff for `core`.
##
## Submodule Documentations:
## - [binfield](./core/binfield.html)
## - [nazopuyo](./core/nazopuyo.html)
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./core/[binaryfield, nazopuyo]

export binaryfield, nazopuyo
