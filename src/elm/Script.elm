module Script (..) where

import Signal exposing (Signal)
import Json.Encode exposing (Value)


type MultiScript workerModel supervisorModel
  = Worker workerModel
  | Supervisor (Set WorkerId) supervisorModel


type alias WorkerId =
  Int


type alias Distribute workerModel supervisorModel =
  { worker :
      { update : Value -> workerModel -> ( workerModel, WorkerAction )
      , init : ( workerModel, WorkerAction )
      }
  , supervisor :
      { update : WorkerId -> Value -> supervisorModel -> ( supervisorModel, SupervisorAction )
      , init : ( supervisorModel, SupervisorAction )
      }
  , receiveMessage : Signal Value
  , sendMessage : Signal Value
  }


receiveMessage : Value
receiveMessage value =
  case decodeValue supervisorMessageDecoder value of
    Ok Init ->
      Debug.crash "TODO init"

    Ok (MessageFromWorker workerId data) ->
      Debug.crash "TODO pass these args to update"

    Err msg ->
      Debug.crash "TODO send error back out to the parent"


supervisorMessageDecoder : Decoder SupervisorMessage
type SupervisorMessage
  = Init
  | MessageFromWorker WorkerId Value


distribute : Distribute -> Script
distribute config =
  Debug.crash "TODO"


messageDecoder : Decoder
messageDecoder =
  Debug.crash "TODO"
