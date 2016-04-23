var Supervisor = require("elm-node-app").Supervisor;
var Elm = require("./Elm.js");

var elmApp = Elm.worker(Elm.Example, {receiveMessage: null});

supervisor = new Supervisor(elmApp);

supervisor.on("message", function(msg) {
  console.log("Received message:", msg);
});

supervisor.on("close", function(msg) {
  console.log("Closed with message:", msg);
});

supervisor.start();

supervisor.send({msgType: "echo", data: "yo!"});


process.stdin.resume();
process.stdin.setEncoding('utf8');

var util = require("util");

process.stdin.on("data", function (text) {
  console.log("You said: ", util.inspect(text));

  if (text === "quit\n") {
    done();
  }
});

function done() {
  process.exit();
}
