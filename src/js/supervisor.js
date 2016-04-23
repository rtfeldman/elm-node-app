var Worker = require("webworker-threads").Worker;
var EventEmitter = require("event-emitter");

function Supervisor(elmApp, sendMessagePortName, receiveMessagePortName) {
  if (typeof sendMessagePortName === "undefined") {
    sendMessagePortName = "sendMessage";
  } else if (typeof sendMessagePortName !== "string") {
    throw new Error("Invalid sendMessagePortName: " + sendMessagePortName);
  }

  if (typeof receiveMessagePortName === "undefined") {
    receiveMessagePortName = "receiveMessage";
  } else if (typeof receiveMessagePortName !== "string") {
    throw new Error("Invalid receiveMessagePortName: " + receiveMessagePortName);
  }

  // Validate that elmApp looks right.
  if (typeof elmApp !== "object") {
    throw new Error("Invalid elmApp: " + elmApp);
  } else if (typeof elmApp.ports !== "object") {
    throw new Error("The provided elmApp is missing a `ports` field.");
  }

  [sendMessagePortName, receiveMessagePortName].forEach(function(portName) {
    if (typeof elmApp.ports[portName] !== "object") {
      throw new Error("The provided elmApp does not have a valid a port called `" + portName + "`.");
    }
  });

  // Set up methods

  var emitter = new EventEmitter();
  var ports = elmApp.ports;
  var subscribe = ports[sendMessagePortName].subscribe;
  var send = ports[receiveMessagePortName].send

  for (var index = 0; index < methodsToCopy.length; index++) {
    var key = methodsToCopy[index];
    var method = emitter[key];

    this[key] = function() { return method.apply(emitter, arguments); }
  }

  var started = false; // CAUTION: this gets mutated!

  this.start = function() {
    if (started) {
      throw new Error("Attempted to start a supervisor that was already started!");
    } else {
      supervise(subscribe, send, this.emit);
    }
  }

  this.send = function(data) {
    return send({forWorker: false, workerId: null, data: data});
  }

  return this;
}

function supervise(subscribe, send, emit) {
  var workers = {};

  function emitClose(msg) {
    emit("close", msg);
  }

  function emitMessage(msg) {
    emit("message", msg);
  }

  function terminateWorkers() {
    Object.values(workers).forEach(function(worker) {
      worker.terminate();
    });
  }

  function handleMessage(msg) {
    var workerId = msg.workerId;

    if (workerId === null) {
      // Receiving a null workerId indicates a message for JS.
      if (msg.data === null) {
        // Receiving null workerId and null data means "terminate"
        terminateWorkers();

        // We're done!
        return emitClose(null);
      } else {
        // Receiving a null workerId but non-null data means we should emit it.
        return emitMessage(msg.data);
      }
    } if (typeof workerId !== "string") {
      terminateWorkers();

      emitClose("Error: Cannot send message " + msg + " to workerId `" + workerId + "`!");
    } else {
      if (!workers.hasOwnProperty(workerId)) {
        // This workerId is unknown to us; init a new worker before sending.
        var worker = new Worker("worker.js");

        worker.onmessage = function(data) {
          // When the worker sends a message, tag it with this workerId
          // and then send it along
          send({forWorker: true, workerId: workerId, data: data});
        };

        // Record this new worker in the lookup table.
        workers[workerId] = worker;
      }

      workers[workerId].postMessage({moduleName: moduleName, data: msg});
    }
  }

  subscribe(function(messages) {
    try {
      messages.forEach(handleMessage);
    } catch (err) {
      terminateWorkers();
      emitClose(err);
    }
  });
}

var methodsToCopy = ["on", "off", "emit"];

module.exports.Supervisor = Supervisor;
