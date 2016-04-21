var Worker = require("webworker-threads").Worker;
var Elm = require("Elm");

var worker;

self.onmessage = function(messages) {
  if (typeof worker === "undefined") {
    worker = Elm.worker(Elm[moduleName], {});

    worker.ports.sendMessage.subscribe(function(msg) {
      self.postMessage(msg);
    });
  }

  messages.forEach(function(msg) {
    switch (msg.cmd) {
      case "terminate":
        return self.close();

      case "send":
        return worker.ports.receiveMessage.send({recipient: null, data: msg.data});

      default:
        throw new Error("Unrecognized worker command: " + msg.cmd);
    }
  });
};
