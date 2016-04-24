var Supervisor = require("elm-node-app").Supervisor;
var Elm = require("./Elm.js");

var elmApp = Elm.worker(Elm.Example, {receiveMessage: null});

supervisor = new Supervisor(elmApp);

supervisor.on("emit", function(msg) {
  console.log("[supervisor]:", msg);
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
  var val = util.inspect(text);

  supervisor.send({msgType: "echo", data: val});

  if (text === "quit\n") {
    done();
  }
});

function done() {
  process.exit();
}
