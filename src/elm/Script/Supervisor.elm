module Script.Supervisor (Cmd, terminate, send, batch, none, WorkerId, encodeCmd) where

import Json.Encode as Encode exposing (Value)


type alias WorkerId =
  String


{-| A command the supervisor can run.
-}
type Cmd
  = Terminate
  | Send WorkerId Value
  | Batch (List Cmd)


{-| Serialize a `Cmd` into a list of `Json.Value` instances.
-}
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


{-| Terminate the supervisor and all workers.
-}
terminate : Cmd
terminate =
  Terminate


{-| Send a `Json.Value` to a particular worker.
-}
send : WorkerId -> Value -> Cmd
send =
  Send


{-| Combine several supervisor commands.
-}
batch : List Cmd -> Cmd
batch =
  Batch


{-| Do nothing.
-}
none : Cmd
none =
  batch []
