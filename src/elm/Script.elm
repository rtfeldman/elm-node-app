module Script (..) where

import Signal exposing (Signal)
import Json.Decode as Decode exposing (Value, Decoder, (:=), decodeValue)
import Json.Decode.Extra as Extra
import Json.Encode as Encode
import Script.Worker as Worker
import Script.Supervisor as Supervisor exposing (WorkerId, SupervisorMsg(..))


type alias Distribute workerModel supervisorModel =
  { worker :
      { update : Value -> workerModel -> ( workerModel, Worker.Cmd )
      , init : ( workerModel, Worker.Cmd )
      }
  , supervisor :
      { update : SupervisorMsg -> supervisorModel -> ( supervisorModel, Supervisor.Cmd )
      , init : ( supervisorModel, Supervisor.Cmd )
      }
  , receiveMessage : Signal Value
  }


messageDecoder : Decoder ( Bool, Maybe WorkerId, Value )
messageDecoder =
  Decode.object3 (,,) ("forWorker" := Decode.bool) ("workerId" := (Extra.maybeNull Decode.string)) ("data" := Decode.value)


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
        ( _, Err err ) ->
          Debug.crash ("Malformed JSON received: " ++ err)

        ( Uninitialized, Ok ( False, _, data ) ) ->
          let
            -- We've received a supervisor message; we must be a supervisor!
            ( model, cmd ) =
              config.supervisor.init

            ( workerModel, _ ) =
              config.worker.init
          in
            case handleMessage msg ( (Supervisor workerModel model), None ) of
              ( newRole, SupervisorCmd newCmd ) ->
                ( newRole, SupervisorCmd (Supervisor.batch [ cmd, newCmd ]) )

              ( _, WorkerCmd _ ) ->
                Debug.crash "On init, received a worker command instead of the expected supervisor command"

              ( _, None ) ->
                Debug.crash "On init, received a None command instead of the expected supervisor command"

        ( Uninitialized, Ok ( True, _, data ) ) ->
          let
            -- We've received a worker message; we must be a worker!
            ( model, cmd ) =
              config.worker.init

            ( supervisorModel, _ ) =
              config.supervisor.init
          in
            case handleMessage msg ( (Worker model supervisorModel), None ) of
              ( newRole, WorkerCmd newCmd ) ->
                ( newRole, WorkerCmd (Worker.batch [ cmd, newCmd ]) )

              ( _, SupervisorCmd _ ) ->
                Debug.crash "On init, received a supervisor command instead of the expected worker command"

              ( _, None ) ->
                Debug.crash "On init, received a None command instead of the expected worker command"

        ( Supervisor workerModel model, Ok ( False, maybeWorkerId, data ) ) ->
          let
            -- We're a supervisor; process the message accordingly
            subMsg =
              case maybeWorkerId of
                Nothing ->
                  FromOutside data

                Just workerId ->
                  FromWorker workerId data

            ( newModel, cmd ) =
              config.supervisor.update subMsg model
          in
            ( Supervisor workerModel newModel, SupervisorCmd cmd )

        ( Worker model supervisorModel, Ok ( True, Nothing, data ) ) ->
          let
            -- We're a worker; process the message accordingly
            ( newModel, cmd ) =
              config.worker.update data model
          in
            ( Worker newModel supervisorModel, WorkerCmd cmd )

        ( Worker _ _, Ok ( True, Just _, data ) ) ->
          Debug.crash ("Received workerId message intended for a worker.")

        ( Worker _ _, Ok ( False, _, _ ) ) ->
          Debug.crash ("Received supervisor message while running as worker.")

        ( Supervisor _ _, Ok ( True, _, _ ) ) ->
          Debug.crash ("Received worker message while running as supervisor.")
  in
    Signal.foldp handleMessage ( Uninitialized, None ) config.receiveMessage
      |> Signal.filterMap (snd >> cmdToMsg) Encode.null


cmdToMsg : Cmd -> Maybe Value
cmdToMsg rawCmd =
  case rawCmd of
    SupervisorCmd cmd ->
      cmd
        |> Supervisor.encodeCmd
        |> Encode.list
        |> Just

    WorkerCmd cmd ->
      cmd
        |> Worker.encodeCmd
        |> Encode.list
        |> Just

    None ->
      Nothing
