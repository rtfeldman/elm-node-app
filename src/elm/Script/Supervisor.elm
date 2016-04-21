module Script.Supervisor (Cmd, terminate, send, batch, none, WorkerId, encodeCmd) where

import Json.Encode as Encode exposing (Value)


type alias WorkerId =
  String


type Cmd
  = Terminate
  | Send WorkerId Value
  | Batch (List Cmd)


encodeCmd : Cmd -> List Value
encodeCmd cmd =
  case cmd of
    Terminate ->
      -- Sending a null workerId terminates the supervisor.
      [ Encode.object
          [ ( "workerId", Encode.null )
          , ( "data", Encode.null )
          ]
      ]

    Send workerId data ->
      [ Encode.object
          [ ( "workerId", Encode.string workerId )
          , ( "data", data )
          ]
      ]

    Batch cmds ->
      List.concatMap encodeCmd cmds


terminate : Cmd
terminate =
  Terminate


send : WorkerId -> Value -> Cmd
send =
  Send


batch : List Cmd -> Cmd
batch =
  Batch


none : Cmd
none =
  batch []
