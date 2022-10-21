// Requests or operations from the controller to the coffee maker

// whenever the coffee maker starts or resets
event eWarmUpReq;
event eWarmUpCompleted;

// grind beans
event eGrindBeansReq;
event eGrindBeansCompleted;

// brew coffee
event eStartEspressoReq;
event eEspressoCompleted;

// steamer
event eStartSteamerReq;
event eStopSteamerReq;

// error messages from coffee maker to control panel/controller
event eNoWaterError;
event eNoBeansError;
event eWarmerError;


/*

EspressoCoffeeMaker receives requests from the control panel of the coffee
machine and based on its state, the maker responds to the controller if the
operation succeeded or errored
*/
machine EspressoCoffeeMaker {
  var controller: CoffeeMakerControlPanel;
  start state WaitForRequests {
    entry (c: CoffeeMakerControlPanel) {
      controller = c;
    }

    on eWarmUpReq do {
      send controller, eWarmUpCompleted;
    }

    on eGrindBeansReq do {
      if (HasBeans()){
        send controller, eGrindBeansCompleted;
      }else {
        send controller, eNoBeansError;
      }
    }

    on eStartEspressoReq do {
      if (HasWater()){
        send controller, eEspressoCompleted;
      } else {
        send controller, eNoWaterError;
      }
    }

    on eStartSteamerReq do {
      if (!HasWater()) {
        send controller, eNoWaterError;
      }
    }

    on eStopSteamerReq do {
      // do nothing, steamer stopped
    }
  }

  // nondeterministic functions to trigger different behaviours
  fun HasBeans() : bool { return $; }
  fun HasWater() : bool { return $; }
}
