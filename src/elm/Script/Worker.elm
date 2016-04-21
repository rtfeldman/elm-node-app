module Script.Worker (Cmd, send, terminate, batch, none, encodeCmd) where

import Json.Encode as Encode exposing (Value)


type Cmd
  = Send Value
  | Terminate
  | Batch (List Cmd)


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


send : Value -> Cmd
send =
  Send


terminate : Cmd
terminate =
  Terminate


batch : List Cmd -> Cmd
batch =
  Batch


none : Cmd
none =
  batch []
