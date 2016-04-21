module Script (..) where

import Signal exposing (Signal)
import Json.Decode exposing (Value, Decoder, decodeValue)
import Set exposing (Set)
import Script.Worker as Worker
import Script.Supervisor as Supervisor exposing (WorkerId)


type MultiScript workerModel supervisorModel
  = Worker workerModel
  | Supervisor (Set WorkerId) supervisorModel


type alias Distribute workerModel supervisorModel =
  { worker :
      { update : Value -> workerModel -> ( workerModel, Worker.Cmd )
      , init : ( workerModel, Worker.Cmd )
      }
  , supervisor :
      { update : WorkerId -> Value -> supervisorModel -> ( supervisorModel, Supervisor.Cmd )
      , init : ( supervisorModel, Supervisor.Cmd )
      }
  , receiveMessage : Signal Value
  , sendMessage : Signal Value
  }


receiveMessage : Value -> a
receiveMessage value =
  case decodeValue supervisorMessageDecoder value of
    Ok Init ->
      Debug.crash "TODO init"

    Ok (MessageFromWorker workerId data) ->
      Debug.crash "TODO pass these args to update"

    Err msg ->
      Debug.crash "TODO send error back out to the parent"


supervisorMessageDecoder : Decoder SupervisorMessage
supervisorMessageDecoder =
  Debug.crash "TODO"


type SupervisorMessage
  = Init
  | MessageFromWorker WorkerId Value


distribute : Distribute a b -> c
distribute config =
  Debug.crash "TODO"


messageDecoder : Decoder
messageDecoder =
  Debug.crash "TODO"
