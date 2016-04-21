var Worker = require("webworker-threads").Worker;
var Elm = require("Elm");

var worker;

function init(moduleName) {
  if (typeof worker === "undefined") {
    worker = Elm.worker(Elm[moduleName], {});

    worker.ports.receiveMessage.subscribe(function(msg) {
      self.postMessage(msg);
    });
  } else {
    throw new Error("Cannot init() a worker that has already been initialized!");
  }
}

self.onmessage = function(event) {
  if (event.msgType === "init") {
    init(event.moduleName);
  }

  if (worker === "undefined") {
    throw new Error ("Attempted to send message \"" + event + "\" to a worker that had not been initialized yet!");
  } else {
    worker.ports.sendMessage.send(event.data);
  }
};
