enum tCoffeeMakerOperations {
  CM_PressEspressoButton,
  CM_PressSteamerButton,
  CM_PressResetButton,
  CM_ClearGrounds
}

/*
A SaneUser who knows how to use the CoffeeMaker

*/
machine SaneUser {
  var cPanel: CoffeeMakerControlPanel;
  var cups: int;
  start state Init {
    entry (coffeeMaker: CoffeeMakerControlPanel) {
      cPanel = coffeeMaker;
      // inform control panel that I am the user
      send cPanel, eCoffeeMachineUser, this;
      // want to make 2 cups of espresso
      cups = 2;
      goto LetsMakeCoffee;
    }
  }

  state LetsMakeCoffee {
    entry {
      while (cups > 0) {
        // wait for coffee maker to be ready
        WaitForCoffeeMakerToBeReady();
        // press espresso button
        PerformOperationOnCoffeeMaker(cPanel, CM_PressEspressoButton);
        // check the status of the machine
        receive {
          case eEspressoCompleted: { cups = cups - 1; }
          case eCoffeeMakerError: (status: tCoffeeMakerState) {
            // lets fill beans or water and reset the machine and go back
            // to making espresso
            PerformOperationOnCoffeeMaker(cPanel, CM_PressResetButton);
          }
        }
      }
      // clear coffee grounds before leaving.
      PerformOperationOnCoffeeMaker(cPanel, CM_ClearGrounds);
      raise halt; // done
    }
  }
}

/*

A crazy user who gets excited by looking at a coffee machine and starts stress
testing the machine by pressing all sorts of random buttons and opening/closing
doors
*/
machine CrazyUser {
  var cPanel: CoffeeMakerControlPanel;
  var numOperations: int;
  start state StartPressingButtons {
    entry (config: (coffeeMaker: CoffeeMakerControlPanel, nOps: int)) {
      var pickedOps: tCoffeeMakerOperations;
      numOperations = config.nOps;
      cPanel = config.coffeeMaker;
      // inform control panel that I am the user
      send cPanel, eCoffeeMachineUser, this;
      while(numOperations > 0) {
        pickedOps = PickRandomOperationToPerform();
        PerformOperationOnCoffeeMaker(cPanel, pickedOps);
        numOperations = numOperations - 1;
      }
    }
    // ignore all the responses from the coffee maker
    ignore eCoffeeMakerError, eEspressoCompleted, eCoffeeMakerReady;
  }

  // pick random operation
  fun PickRandomOperationToPerform() : tCoffeeMakerOperations {
    var op_i: int;
    op_i =  choose(3);
    if(op_i == 0) return CM_PressEspressoButton;
    else if(op_i == 1) return CM_PressSteamerButton;
    else if(op_i == 2) return CM_PressResetButton;
    else return CM_ClearGrounds;
  }
}

// function to perform an operation on the CoffeeMaker
fun PerformOperationOnCoffeeMaker(cPanel: CoffeeMakerControlPanel, CM_Ops: tCoffeeMakerOperations)
{
  if(CM_Ops == CM_PressEspressoButton) send cPanel, eEspressoButtonPressed;
  else if(CM_Ops == CM_PressSteamerButton) {
    send cPanel, eSteamerButtonOn;
    // wait for some time and then release the button
    send cPanel, eSteamerButtonOff;
  } else if(CM_Ops == CM_ClearGrounds) {
    send cPanel, eOpenGroundsDoor;
    // empty ground and close the door
    send cPanel, eCloseGroundsDoor;
  } else if(CM_Ops == CM_PressResetButton) {
    send cPanel, eResetCoffeeMaker;
  }
}

fun WaitForCoffeeMakerToBeReady() {
  receive {
    case eCoffeeMakerReady: {}
    case eCoffeeMakerError: (status: tCoffeeMakerState){ raise halt; }
  }
}
module Users = { SaneUser, CrazyUser };
