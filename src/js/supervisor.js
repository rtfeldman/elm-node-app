var Worker = require("webworker-threads").Worker;

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

  this.send = send;
  this.addEventListener = emitter.addEventListener;
  this.removeEventListener = emitter.removeEventListener;

  var started = false; // CAUTION: this gets mutated!

  this.start = function() {
    if (started) {
      throw new Error("Attempted to start a supervisor that was already started!");
    } else {
      supervise(subscribe, send, emitter.emit);
    }
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
      // Receiving a workerId of null indicates a message for JS.
      switch (msg.msgType) {
        case "close":
          terminateWorkers();

          // We're done!
          return emitClose(null);
        case "message":
          return emitMessage(msg.data);

        default:
          throw new Error("Unrecognized msgType: " + msg.msgType);
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
          send({recipient: workerId, data: data});
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
