var Supervisor = require("elm-node-app").Supervisor;
var Elm = require("./Elm.js");

var elmApp = Elm.worker(Elm.Example, {receiveMessage: null});

supervisor = new Supervisor(elmApp);

supervisor.addEventListener("message", function(msg) {
  console.log("Received message:", msg);
});

supervisor.addEventListener("close", function(msg) {
  console.log("Closed with message:", msg);
});

supervisor.start();

supervisor.send("yo!");
