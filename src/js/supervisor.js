var Worker = require("webworker-threads").Worker;
var Elm = require("Elm");

function start(moduleName, args) {
  // Optional arguments to pass in, in case you have static ports defined that
  // you'd like to receive them.
  if (typeof args === "undefined") {
    args = {};
  }

  return new Promise(function(resolve, reject) {
    var supervisor = Elm.worker(Elm[moduleName], args);
    var workers = {};

    fucntion terminateWorkers() {
      Object.values(workers).forEach(function(worker) {
        worker.terminate();
      });
    }

    function handleMessage(msg) {
      var workerId = msg.workerId;

      if (workerId === null) {
        // Receiving a workerId of null indicates that we should shut down.
        terminateWorkers();

        // We're done!
        resolve(msg.data);
      } if (typeof workerId !== "string") {
        terminateWorkers();

        reject("Cannot send message " + msg + " to workerId `" + workerId + "`!");
      } else {
        if (!workers.hasOwnProperty(workerId)) {
          // This workerId is unknown to us; init a new worker before sending.
          var worker = new Worker("worker.js");

          worker.onmessage = function(data) {
            // When the worker sends a message, tag it with this workerId
            // and then pass it along to the supervisor.
            supervisor.ports.receiveMessage.send({recipient: workerId, data: data});
          };

          // Record this new worker in the lookup table.
          workers[workerId] = worker;
        }

        workers[workerId].postMessage({moduleName: moduleName, data: msg});
      }
    }

    supervisor.ports.sendMessage.subscribe(function(messages) {
      try {
        messages.forEach(handleMessage);
      } catch (err) {
        terminateWorkers();
        reject(err);
      }
    });
  });
}
