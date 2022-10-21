type tSystemConfig = (
  numNodes: int,
  numClients: int
);

machine TestMultipleClients {
  start state Init {
    entry {
      var config: tSystemConfig;
      config = (numNodes = 3, numClients = 2);
      SetupSystemWithFailureInjector(config);
    }
  }
}

fun SetupSystemWithFailureInjector(config: tSystemConfig) {
  var i : int;
  var nodes: set[Node];
  var clients: set[Client];
  while(i < config.numNodes) {
    nodes += (new Node());
    i = i + 1;
  }
  i = 0;
  while(i < config.numClients) {
    clients += (new Client(nodes));
    i = i + 1;
  }
  new FailureDetector((nodes = nodes, clients = clients));
  new FailureInjector((nodes = nodes, nFailures = sizeof(nodes)/2 + 1));
}
