var Worker = require("webworker-threads").Worker;
var Elm = require("Elm");

function start(moduleName) {
  return new Promise(function(resolve, reject) {
    var supervisor = Elm.worker(Elm[moduleName], {});
    var workers = {};

    fucntion terminateWorkers() {
      Object.values(workers).forEach(function(worker) {
        worker.terminate();
      });
    }

    supervisor.ports.sendMessage.subscribe(function(msg) {
      try {
        var workerId = msg.workerId;

        if (workerId === null) {
          // Receiving a workerId of null indicates that we should shut down.
          terminateWorkers();

          // We're done!
          resolve(msg.data);
        } if (typeof workerId !== "number") {
          terminateWorkers();

          reject("Cannot send message " + msg + " to workerId `" + workerId + "`!");
        } else {
          if (workers.hasOwnProperty(workerId)) {
            // We recognize this workerId; send the message along as normal.
            workers[workerId].postMessage({msgType: "normal", moduleName: moduleName, data: msg});
          } else {
            // This workerId is unknown to us; init a new worker, then send.
            var worker = new Worker("worker.js");

            worker.onmessage = function(data) {
              // When the worker sends a message, tag it with this workerId
              // and then pass it along to the supervisor.
              supervisor.ports.receiveMessage.send({workerId: workerId, data: data});
            };

            // Record this new worker in the lookup table.
            workers[workerId] = worker;

            // Init the worker with the moduleName, and give it its first msg.
            worker.postMessage({msgType: "init", moduleName: moduleName, data: msg});
          }
        }
      } catch (err) {
        terminateWorkers();
        reject(err);
      }
    });

    // Sending a workerId of null tells the supervisor to initialize.
    supervisor.ports.receiveMessage.send({workerId: null, data: null});
  });
}
