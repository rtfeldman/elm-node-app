module Script.Supervisor (..) where


type Cmd
  = Terminate
  | TerminateWorker WorkerId
  | Send WorkerId Value
  | Batch (List Cmd)
