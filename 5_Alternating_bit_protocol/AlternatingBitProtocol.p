event eEvent; 

machine Sender {
  start state Init { }
}

machine Receiver {
  start state Init { }
}

machine TestProtocol {
  start state Init { }
}

spec Spec observes eEvent {
  start state Init { }
}


test Test [main=TestProtocol] :
  assert Spec in {TestProtocol, Sender, Receiver};
