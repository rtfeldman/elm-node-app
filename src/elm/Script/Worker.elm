module Script.Worker (..) where

import Json.Encode exposing (Value)


type Cmd
  = Send Value
  | Batch (List Cmd)
