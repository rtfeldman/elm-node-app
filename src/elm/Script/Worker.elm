module Script.Worker (Cmd, send, batch, none) where

import Json.Encode exposing (Value)


type Cmd
  = Send Value
  | Batch (List Cmd)


send : Value -> Cmd
send =
  Send


batch : List Cmd -> Cmd
batch =
  Batch


none : Cmd
none =
  batch []
