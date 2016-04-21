module Script.Supervisor (..) where

import Json.Encode exposing (Value)


type alias WorkerId =
  Int


type Cmd
  = Terminate
  | TerminateWorker WorkerId
  | Send WorkerId Value
  | Batch (List Cmd)
