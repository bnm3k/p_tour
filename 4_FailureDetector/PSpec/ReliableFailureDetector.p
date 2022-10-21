spec ReliableFailureDetector observes eNotifyNodesDown, eShutDown {
  var nodesShutdownAndNotDetected: set[Node];
  var nodesDownDetected: set[Node];

  start state AllShutdownNodesAreDetected {
    // whenever the failure-detector broadcasts to clients the event
    // eNotifyNodesDown with the set of notRespondedNodes, we mark these nodes
    // as 'detected' in that they were detected as down and the clients
    // successfully made aware
    on eNotifyNodesDown do (nodes: set[Node]) {
      var i: int;
      while(i < sizeof(nodes)) {
        nodesShutdownAndNotDetected -= (nodes[i]);
        nodesDownDetected += (nodes[i]);
        i = i + 1;
      }
    }


    // when a node is shutdown ie on event eShutDown, if is not already in
    // nodesDownDetected, we add it to nodesShutdownAndNotDetected then go to
    // state NodesShutDownButNotDetected
    on eShutDown do (n: machine) {
      if(!((n as Node) in nodesDownDetected)) {
        nodesShutdownAndNotDetected += (n as Node);
        goto NodesShutDownButNotDetected;
      }
    }
  }

  hot state NodesShutDownButNotDetected {
    on eNotifyNodesDown do (nodes: set[Node]) {
      var i: int;
      while(i < sizeof(nodes)) {
        nodesShutdownAndNotDetected -= (nodes[i]);
        nodesDownDetected += (nodes[i]);
        i = i + 1;
      }
      if(sizeof(nodesShutdownAndNotDetected) == 0)
        goto AllShutdownNodesAreDetected;
    }

    on eShutDown do (node: machine) {
      if(!((node as Node) in nodesDownDetected))
        nodesShutdownAndNotDetected += (node as Node);
    }
  }
}
