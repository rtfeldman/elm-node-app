module Example (..) where

import Signal exposing (Signal)
import Json.Encode exposing (Value)
import Script
import Script.Supervisor as Supervisor exposing (WorkerId)
import Script.Worker as Worker


type alias WorkerModel =
  { workerStuff : Int }


type alias SupervisorModel =
  { supervisorStuff : String }


updateWorker : Value -> WorkerModel -> ( WorkerModel, Worker.Cmd )
updateWorker data model =
  if model.workerStuff > 0 then
    Debug.crash "TODO"
  else
    Debug.crash "TODO"


updateSupervisor : WorkerId -> Value -> SupervisorModel -> ( SupervisorModel, Supervisor.Cmd )
updateSupervisor workerId data model =
  if model.supervisorStuff == "blah" then
    Debug.crash "TODO"
  else
    Debug.crash "TODO"


port sendMessage : Signal Value
port sendMessage =
  Script.start
    { worker =
        { update = updateWorker
        , init = ( (WorkerModel 42), Worker.none )
        }
    , supervisor =
        { update = updateSupervisor
        , init = ( (SupervisorModel "foo"), Supervisor.none )
        }
    , receiveMessage = receiveMessage
    }


port receiveMessage : Signal Value
