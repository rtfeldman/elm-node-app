module Example (..) where

import Task exposing (Task, Never)
import Signal exposing (Signal)
import Json.Encode exposing (Value)


port tasks : Signal (Task Never ())
port receiveMessage : Signal Value
port sendMessage : Signal Value
port sendMessage =
  Test.start run tasks suites
