// Events used by the user to interact with the control panel of the Coffee
// Machine
event eEspressoButtonPressed; // make espresso button pressed
event eSteamerButtonOff; // steamer button turned off
event eSteamerButtonOn; // streamer button turned on
event eOpenGroundsDoor; // door opened to empty grounds
event eCloseGroundsDoor; // door closed after emptying grounds
event eResetCoffeeMaker; // reset coffee maker button pressed
event eCoffeeMakerError: tCoffeeMakerState; // error message from panel to user
event eCoffeeMakerReady; // coffee machine is ready
event eCoffeeMachineUser: machine; // coffee machine user

// represents the state of the coffee maker
enum tCoffeeMakerState {
  NotWWarmedUp,
  Ready,
  NoBeansError,
  NoWaterError
}

/*

CoffeeMakerControlPanel acts as the interface between the CoffeeMaker and User
It converts the inputs from the user to appropriate inputs to the CoffeeMaker
and sends responses to the user
*/
machine CoffeeMakerControlPanel {
  var coffeeMaker: EspressoCoffeeMaker;
  var coffeeMakerState: tCoffeeMakerState;
  var currentUser: machine;

  start state Init {
    entry {
      coffeeMakerState = NotWWarmedUp;
      coffeeMaker = new EspressoCoffeeMaker(this);
      WaitForUser();
      goto WarmUpCoffeeMaker;
    }
  }

  // block until a user shows up
  fun WaitForUser() {
    receive {
      case eCoffeeMachineUser: (user: machine) {
        currentUser = user;
      }
    }
  }

  state WarmUpCoffeeMaker {
    entry {
      // inform the specification about the current state of the coffee maker
      announce eInWarmUpState;
      BeginHeatingCoffeeMaker();
    }
    on eWarmUpCompleted goto CoffeeMakerReady;
    // grounds door is opened or closed, handle it ater after the coffee maker
    // has warmed up
    defer eOpenGroundsDoor, eCloseGroundsDoor;
    // ignore these inputs from users unti the maker has warmed up
    ignore eEspressoButtonPressed, eSteamerButtonOn, eSteamerButtonOff,
      eResetCoffeeMaker;
    // ignore these errors and responses as they could be from previous state
    ignore eNoBeansError, eNoWaterError, eGrindBeansCompleted;
  }

  state CoffeeMakerReady {
    entry {
      // inform the specification about the current state of the coffee maker
      announce eInReadyState;
      coffeeMakerState = Ready;
      send currentUser, eCoffeeMakerReady;
    }
    on eOpenGroundsDoor goto CoffeeMakerDoorOpened;
    on eEspressoButtonPressed goto CoffeeMakerRunGrind;
    on eSteamerButtonOn goto CoffeeMakerRunSteam;
    // ignore these out of order commands, these must have happened because
    // of an error from user or sensor
    ignore eSteamerButtonOff, eCloseGroundsDoor;
    // ignore commands and errors as they are from previous state
    ignore eWarmUpCompleted, eResetCoffeeMaker, eNoBeansError, eNoWaterError;
  }

  state CoffeeMakerDoorOpened {
    on eCloseGroundsDoor do {
      if (coffeeMakerState == NotWWarmedUp) goto WarmUpCoffeeMaker;
      else goto CoffeeMakerReady;
    }
  }

  state CoffeeMakerRunGrind {
    entry {
      // inform the specification about the current state of the coffee maker
      announce eInBeansGrindingState;
      GrindBeans();
    }
    on eNoBeansError goto EncounteredError with {
      coffeeMakerState = NoBeansError;
      print "No beans to grind! Please refill beans and reset the machine!";
    }
    on eNoWaterError goto EncounteredError with {
      coffeeMakerState = NoWaterError;
      print "No water! Please refill water and reset the machine!";
    }
    on eGrindBeansCompleted goto CoffeeMakerRunEspresso;
    defer eOpenGroundsDoor, eCloseGroundsDoor, eEspressoButtonPressed;
    // can't make steam while we are making espresso
    ignore eSteamerButtonOn, eSteamerButtonOff;
    // ignore commands that are old or can't be handled right now
    ignore eWarmUpCompleted, eResetCoffeeMaker;
  }

  state CoffeeMakerRunEspresso {
    entry {
      // inform the specification about the current state of the coffee maker
      announce eInCoffeeBrewingState;
      StartEspresso();
    }
    on eEspressoCompleted goto CoffeeMakerReady with {send currentUser, eEspressoCompleted;}
    on eNoWaterError goto EncounteredError with {
      coffeeMakerState = NoWaterError;
      print "No water! Please refill water and reset the machine!";
    }
    // the user commands will be handled next after finishing this espresso
    defer eOpenGroundsDoor, eCloseGroundsDoor, eEspressoButtonPressed;
    // can't make steam while we are making espresso
    ignore eSteamerButtonOn, eSteamerButtonOff;
    // ignore old commands and cannot reset when making coffee
    ignore eWarmUpCompleted, eResetCoffeeMaker;
  }

  state CoffeeMakerRunSteam {
    entry {StartSteamer();}
    on eSteamerButtonOff goto CoffeeMakerReady with { StopSteamer();}
    on eNoWaterError goto EncounteredError with {
      StopSteamer();
      print "No Water! Please refill water and reset the machine!";
    }
    // user might have cleaned grounds while steaming
    defer eOpenGroundsDoor, eCloseGroundsDoor;
    // can't make espresso while we are making steam;
    ignore eEspressoButtonPressed, eSteamerButtonOn;
  }

  state EncounteredError {
    entry {
      // inform the specification about the current state of the coffee maker
      announce eErrorHappened;
      // send error message to user
      send currentUser, eCoffeeMakerError, coffeeMakerState;
    }
    on eResetCoffeeMaker goto WarmUpCoffeeMaker with {
      // inform the specification about the current state of the coffee maker
      announce eResetPerformed;
    }
    // error ignore these requests until reset
    ignore eEspressoButtonPressed, eSteamerButtonOn, eSteamerButtonOff,
      eOpenGroundsDoor, eCloseGroundsDoor, eWarmUpCompleted, eEspressoCompleted,
      eGrindBeansCompleted;
    // ignore other simulataneious errors
    ignore eNoBeansError, eNoWaterError;
  }

  fun BeginHeatingCoffeeMaker() { send coffeeMaker, eWarmUpReq;  }
  fun StartSteamer() { send coffeeMaker, eStartSteamerReq; }
  fun StopSteamer() { send coffeeMaker, eStopSteamerReq; }
  fun GrindBeans() { send coffeeMaker, eGrindBeansReq; }
  fun StartEspresso() { send coffeeMaker, eStartEspressoReq; }
}
