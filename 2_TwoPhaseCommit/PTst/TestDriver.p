// type that represents the configuration of the system under test
type t2PCConfig = (
  numClients: int,
  numParticipants: int,
  numTransPerClient: int,
  failParticipants: int
);


// function that creates the two phase commit system along with the machine
// inits
fun SetUpTwoPhaseCommitSystem(config: t2PCConfig) {
  var coordinator: Coordinator;
  var participants: set [Participant];
  var i: int;

  // create participants
  while (i < config.numParticipants) {
    participants += (new Participant());
    i = i + 1;
  }

  // initialize the monitors (specifications)
  InitializeTwoPhaseCommitSpecifications(config.numParticipants);

  // create the coordinator
  coordinator = new Coordinator(participants);

  // create the clients
  i = 0;
  while (i < config.numClients) {
    new Client((coordinator=coordinator, n = config.numTransPerClient, id = i + 1));
    i = i + 1;
  }

  // create the failure injector if we want to inject failures
  if(config.failParticipants > 0) {
    CreateFailureInjector((nodes=participants, nFailures = config.failParticipants));
  }
}

fun InitializeTwoPhaseCommitSpecifications(numParticipants: int) {
  // inform the monitor the number of participants in the system
  announce eMonitor_AtomicityInitialize, numParticipants;
}

// This machine creates 3 participants, 1 coordinator and 1 client
machine SingleClientNoFailure {
  start state Init {
    entry {
      var config: t2PCConfig;
      config = (
        numClients = 1,
        numParticipants=3,
        numTransPerClient=2,
        failParticipants=0
      );
      SetUpTwoPhaseCommitSystem(config);
    }
  }
}

// This machine creates 3 participants, 1 coordinator and 2 clients
machine MultipleClientsNoFailure {
  start state Init {
    entry {
      var config: t2PCConfig;
      config = (
        numClients = 2,
        numParticipants=3,
        numTransPerClient=2,
        failParticipants=0
      );
      SetUpTwoPhaseCommitSystem(config);
    }
  }
}

// This machine creates 3 participants, 1 coordinator and 2 clients
machine MultipleClientsWithFailure {
  start state Init {
    entry {
      var config: t2PCConfig;
      config = (
        numClients = 2,
        numParticipants=3,
        numTransPerClient=2,
        failParticipants=1
      );
      SetUpTwoPhaseCommitSystem(config);
    }
  }
}
