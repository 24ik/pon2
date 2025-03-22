## This module implements results type.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import results

export results

type Res*[T] = Result[T, string] ## Result type with the error type string.
