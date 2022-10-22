event eGreetReq: (person: Person, name: string);
event eGreetResp: string;

machine Greeter {
  start state Greet {
    on eGreetReq do (req: (person: Person, name: string)) {
      send req.person, eGreetResp, format("Hello, {0}", req.name);
    }
  }
}

machine Person {
  var name: string;
  var greetingGenerator: Greeter;

  start state Init {
    entry (config: (name:string, greeter:Greeter)) {
      name = config.name;
      greetingGenerator = config.greeter;
      goto WaitForGreeting;
    }
  }

  state WaitForGreeting {
    entry {
      send greetingGenerator, eGreetReq, (person=this, name=name);
    }
    on eGreetResp do (greeting: string) {
      print format("received greeting: {0}", greeting);
    }
  }
}

machine TestGreetingOccurs {
  start state Init {
    entry {
      var greeter: Greeter;
      var name : string;

      greeter = new Greeter();
      name = "Alice";

      new Person((name=name, greeter=greeter));
    }
  }
}

spec GreetingGetsResponse observes eGreetReq, eGreetResp {
  var name: string;
  start state Check {
    on eGreetReq do (req: (person: Person, name:string)){
      name = req.name;
    }

    on eGreetResp do (greeting: string) {
      assert greeting == format("Hello, {0}", name);
    }
  }
}


test Test [main=TestGreetingOccurs] :
  assert GreetingGetsResponse in {Person, Greeter, TestGreetingOccurs};
