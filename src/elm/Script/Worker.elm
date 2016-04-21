module Script.Worker (..) where


type Cmd
  = Send Value
  | Batch (List Cmd)
