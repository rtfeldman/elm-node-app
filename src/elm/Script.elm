module Script (..) where

import Signal exposing (Signal)
import Json.Decode as Decode exposing (Value, Decoder, (:=), decodeValue)
import Json.Decode.Extra as Extra
import Json.Encode as Encode
import Script.Worker as Worker
import Script.Supervisor as Supervisor exposing (WorkerId)


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
  }


messageDecoder : Decoder ( Maybe WorkerId, Value )
messageDecoder =
  Decode.object2 (,) ("recipient" := (Extra.maybeNull Decode.string)) ("data" := Decode.value)


type Role workerModel supervisorModel
  = Supervisor workerModel supervisorModel
  | Worker workerModel supervisorModel
  | Uninitialized


type Cmd
  = SupervisorCmd Supervisor.Cmd
  | WorkerCmd Worker.Cmd
  | None


start : Distribute workerModel supervisorModel -> Signal Value
start config =
  let
    --handleMessage : Value -> ( Role workerModel supervisorModel, Cmd ) -> ( Role workerModel supervisorModel, Cmd )
    handleMessage msg ( role, _ ) =
      case ( role, Decode.decodeValue messageDecoder msg ) of
        ( _, Err msg ) ->
          Debug.crash ("Malformed JSON received " ++ toString msg)

        ( Uninitialized, Ok ( Just workerId, data ) ) ->
          let
            -- We've received a supervisor message; we must be a supervisor!
            ( model, cmd ) =
              config.supervisor.init
          in
            case handleMessage msg ( (Supervisor (fst config.worker.init) model), None ) of
              ( newRole, SupervisorCmd newCmd ) ->
                ( newRole, SupervisorCmd (Supervisor.batch [ cmd, newCmd ]) )

              ( _, WorkerCmd _ ) ->
                Debug.crash "On init, received a worker command instead of the expected supervisor command"

              ( _, None ) ->
                Debug.crash "On init, received a None command instead of the expected supervisor command"

        ( Uninitialized, Ok ( Nothing, data ) ) ->
          let
            -- We've received a worker message; we must be a supervisor!
            ( model, cmd ) =
              config.worker.init
          in
            case handleMessage msg ( (Worker model (fst config.supervisor.init)), None ) of
              ( newRole, WorkerCmd newCmd ) ->
                ( newRole, WorkerCmd (Worker.batch [ cmd, newCmd ]) )

              ( _, SupervisorCmd _ ) ->
                Debug.crash "On init, received a supervisor command instead of the expected worker command"

              ( _, None ) ->
                Debug.crash "On init, received a None command instead of the expected worker command"

        ( Supervisor workerModel model, Ok ( Just workerId, data ) ) ->
          let
            -- We're a supervisor; process the message accordingly
            ( newModel, cmd ) =
              config.supervisor.update workerId data model
          in
            ( Supervisor workerModel newModel, SupervisorCmd cmd )

        ( Worker model supervisorModel, Ok ( Nothing, data ) ) ->
          let
            -- We're a worker; process the message accordingly
            ( newModel, cmd ) =
              config.worker.update data model
          in
            ( Worker newModel supervisorModel, WorkerCmd cmd )

        ( Supervisor _ _, Ok ( Nothing, _ ) ) ->
          Debug.crash ("Received worker message while running as supervisor: " ++ toString msg)

        ( Worker _ _, Ok ( Just _, _ ) ) ->
          Debug.crash ("Received supervisor message while running as worker: " ++ toString msg)
  in
    Signal.foldp handleMessage ( Uninitialized, None ) config.receiveMessage
      |> Signal.map (snd >> cmdToMsg)


cmdToMsg : Cmd -> Value
cmdToMsg rawCmd =
  Encode.list
    <| case rawCmd of
        SupervisorCmd cmd ->
          Supervisor.encodeCmd cmd

        WorkerCmd cmd ->
          Worker.encodeCmd cmd

        None ->
          Debug.crash "Attempted to translate a None command into a message"
