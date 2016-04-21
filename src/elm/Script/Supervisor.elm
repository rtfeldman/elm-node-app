module Script.Supervisor (Cmd, terminate, terminateWorker, send, batch, none, WorkerId) where

import Json.Encode exposing (Value)


type alias WorkerId =
  Int


type Cmd
  = Terminate
  | TerminateWorker WorkerId
  | Send WorkerId Value
  | Batch (List Cmd)


terminate : Cmd
terminate =
  Terminate


terminateWorker : WorkerId -> Cmd
terminateWorker =
  TerminateWorker


send : WorkerId -> Value -> Cmd
send =
  Send


batch : List Cmd -> Cmd
batch =
  Batch


none : Cmd
none =
  batch []
