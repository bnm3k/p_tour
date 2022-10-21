event ePing: (fd: FailureDetector, trial: int); // from failure-detector to node
event ePong: (node: Node, trial: int); // from node to failure-detector
event eNotifyNodesDown: set[Node]; // from failure-detector to client

/*
FailureDetector machine monitors whether a set of nodes in the system are alive
(responsive). It periodically sends ping messages to each node and waits for a
pong message from the nodes.

The nodes that do not send a pong message after multiple attempts are marked as
down or failed and notified to the client nodes so that they can update their
view of the system.

*/
machine FailureDetector {
  var nodes: set[Node]; // set of nodes to be monitored
  var clients: set[Client]; // set of registered clients
  var attempts: int; // number of ping attempts made
  var alive: set[Node]; // set of alive nodes
  var respInCurrRound: set[machine]; // nodes that have responded in curr round
  var timer: Timer; // timer to wait for responses from nodes

  start state Init {
    entry (config: (nodes: set[Node], clients: set[Client])){
      nodes = config.nodes;
      alive = config.nodes;
      clients = config.clients;
      timer = CreateTimer(this);
      goto SendPingsToAllNodes;
    }
  }

  state SendPingsToAllNodes {
    entry {
      var notRespondedNodes: set[Node];
      if (sizeof(alive) == 0) raise halt; // no more work to do
      // compute nodes that have not responded with pongs
      notRespondedNodes = NodesNotRespondedToPing();
      // send ping events to machine that have not responded in the previous
      // attempt
      UnReliableBroadCast(notRespondedNodes, ePing, (fd=this, trial=attempts));
      StartTimer(timer);
    }

    on ePong do (pong: (node: Node, trial: int)) {
      // collect pong responses from alive nodes
      // no need to do any for pong messages from nodes that have been marked
      // failed
      if (pong.node in alive) {
        respInCurrRound += (pong.node);
        if (sizeof(respInCurrRound) == sizeof(alive)) {
          // status of alive nodes has not changed
          CancelTimer(timer);
          goto ResetAndStartAgain;
        }
      }
    }

    // Whenever there's a timeout, we attempt (up to 3 times) to send pings to
    // all nodes. On entry to SendPingsToAllNodes, we send pings unreliably to
    // all nodes that had not responded in the previous round
    on eTimeOut do {
      var notRespondedNodes: set[Node];
      attempts = attempts + 1;
      if (sizeof(respInCurrRound) < sizeof(alive) ) {
        if(attempts < 3) {
          goto SendPingsToAllNodes;
        } else {
          notRespondedNodes = NodesNotRespondedToPing();
          UpdateAliveSet(notRespondedNodes);
          ReliableBroadCast(clients, eNotifyNodesDown, notRespondedNodes);
        }
      }
      goto ResetAndStartAgain;
    }
  }

  state ResetAndStartAgain {
    entry {
      attempts = 0;
      respInCurrRound = default(set[Node]);
      StartTimer(timer);
    }
    on eTimeOut goto SendPingsToAllNodes;
    ignore ePong;
  }

  // respInCurrRound is reset to empty on entry to state ResetAndStartAgain
  // when a node sends pong back, it's added to respInCurrRound
  // if a node is in the `alive` set but not in the `respInCurrRound` set when
  // this function is invoked, then it is regards as "down" after the given
  // timeout.
  // Note, during the first time, this fn returns all the nodes since trivially,
  // no node has responded to a ping at that point.
  fun NodesNotRespondedToPing() : set[Node] {
    var i: int;
    var nodesNotResponded: set[Node];
    while (i < sizeof(nodes)) {
      if (nodes[i] in alive && !(nodes[i] in respInCurrRound)) {
          nodesNotResponded += (nodes[i]);
      }
      i = i + 1;
    }
    return nodesNotResponded;
  }


  fun UpdateAliveSet(nodesDown: set[Node]) {
    var i: int;
    while (i < sizeof(nodesDown)) {
      alive -= (nodesDown[i]);
      i = i + 1;
    }
  }
}
