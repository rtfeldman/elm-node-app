module Example (..) where

import Signal exposing (Signal)
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing ((:=))
import Script
import Script.Supervisor as Supervisor exposing (WorkerId, SupervisorMsg(..))
import Script.Worker as Worker
import String


type alias WorkerModel =
  { id : Int }


type alias SupervisorModel =
  { messagesReceived : List String }


updateWorker : Value -> WorkerModel -> ( WorkerModel, Worker.Cmd )
updateWorker data model =
  case Decode.decodeValue Decode.int data of
    Ok id ->
      ( { model | id = id }, Worker.send (Encode.string ("Hi, my name is Worker " ++ toString id ++ "!")) )

    Err err ->
      ( model, Worker.send (Encode.string ("Error on worker " ++ toString model.id ++ ": " ++ err)) )


updateSupervisor : SupervisorMsg -> SupervisorModel -> ( SupervisorModel, Supervisor.Cmd )
updateSupervisor supervisorMsg model =
  case supervisorMsg of
    FromWorker workerId data ->
      ( model, Supervisor.none )

    FromOutside data ->
      case Decode.decodeValue (Decode.object2 (,) ("msgType" := Decode.string) ("data" := Decode.string)) data of
        Ok ( "echo", msg ) ->
          let
            newMessagesReceived =
              model.messagesReceived ++ [ msg ]

            output =
              "Here are all the messages I've received so far:\n"
                ++ (String.join "\n" newMessagesReceived)
          in
            ( { model | messagesReceived = newMessagesReceived }, Supervisor.emit (Encode.string output) )

        Ok ( msgType, msg ) ->
          Debug.crash ("Urecognized msgType: " ++ msgType ++ " with data: " ++ msg)

        Err err ->
          ( model, Supervisor.emit (Encode.string ("Error decoding message: " ++ toString data ++ " - error was: " ++ err)) )


port sendMessage : Signal Value
port sendMessage =
  Script.start
    { worker =
        { update = updateWorker
        , init = ( (WorkerModel 0), Worker.none )
        }
    , supervisor =
        { update = updateSupervisor
        , init = ( (SupervisorModel []), Supervisor.none )
        }
    , receiveMessage = receiveMessage
    }


port receiveMessage : Signal Value
