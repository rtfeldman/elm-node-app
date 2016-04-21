module Script.Worker (Cmd, send, terminate, batch, none, encodeCmd) where

import Json.Encode as Encode exposing (Value)


{-| A command the worker can run.
-}
type Cmd
  = Send Value
  | Terminate
  | Batch (List Cmd)


{-| Serialize a `Cmd` into a list of `Json.Value` instances.
-}
encodeCmd : Cmd -> List Value
encodeCmd cmd =
  case cmd of
    Send data ->
      [ Encode.object
          [ ( "cmd", Encode.string "send" )
          , ( "data", data )
          ]
      ]

    Terminate ->
      [ Encode.object
          [ ( "cmd", Encode.string "terminate" )
          , ( "data", Encode.null )
          ]
      ]

    Batch cmds ->
      List.concatMap encodeCmd cmds


{-| Send a `Json.Value` to the supervisor.
-}
send : Value -> Cmd
send =
  Send


{-| Terminate this worker.
-}
terminate : Cmd
terminate =
  Terminate


{-| Combine several worker commands.
-}
batch : List Cmd -> Cmd
batch =
  Batch


{-| Do nothing.
-}
none : Cmd
none =
  batch []
