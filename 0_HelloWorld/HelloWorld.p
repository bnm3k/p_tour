event eGreetReq: (person: Person, name: string);
event eGreetResp: string;

machine Greeter {
  start state Greet {
    on eGreetReq do (req: (person: Person, name: string)) {
      send req.person, eGreetResp, "Yebo";
    }
  }
}

machine Person {
  var name: string;
  var greetingGenerator: Greeter;
  start state Init {
    entry (config: (n: string, g: Greeter)) {
      name = config.n;
      greetingGenerator = config.g;
      send greetingGenerator, eGreetReq, (person=this, name=name);
    }
    ignore eGreetResp;
  }
}

machine TestGreetingOccurs {
  start state Init {
    entry {
      var greeter: Greeter;
      greeter = new Greeter();
      new Person((n="Alice", g=greeter));
    }
  }
}

spec GreetingGetsResponse observes eGreetReq, eGreetResp {
  var name: string;
  start state Init {
    on eGreetReq goto WaitForResponse;
  }

  hot state WaitForResponse {
    on eGreetResp goto Done;
  }

  state Done { }
}


module mod = {Person, Greeter,TestGreetingOccurs};
test TestHelloWorld [main=TestGreetingOccurs] :
  assert GreetingGetsResponse in mod;
