/*

The Client machine below implements the client of the two-phase-commit
transaction service

Each client issues N non-deterministic write-transactions, if the transaction
succeeds then it performs a read-transaction on the same key and asserts the
value

*/

machine Client {
  var coordinator: Coordinator;
  var currTransaction: tTrans;
  var N: int; // number of transactions to be issued
  var id: int; // unique client Id

  start state Init {
    entry (payload: (coordinator: Coordinator, n : int, id: int) ) {
      coordinator = payload.coordinator;
      N = payload.n;
      id = payload.id;
      goto SendWriteTransaction;
    }
  }

  state SendWriteTransaction {
    entry {
      if (N > 0) {
        N = N - 1;
        currTransaction = ChooseRandomTransaction(id * 100 + N);
        send coordinator, eWriteTransReq, (client = this, trans = currTransaction);
      }
    }

    on eWriteTransResp goto ConfirmTransaction;
  }

  state ConfirmTransaction {
    entry (writeResp: tWriteTransResp) {
      // if write transaction is successful, then read value and assert that
      // it's the value initially written
      if (writeResp.status == SUCCESS) {
        send coordinator, eReadTransReq, (client=this, key=currTransaction.key);
        return;
      }
      goto SendWriteTransaction;
    }

    on eReadTransResp do (resp: tReadTransResp) {
      assert resp.key == currTransaction.key && (resp.val == currTransaction.val || resp.transId > currTransaction.transId),
        format ("Record read is not same as what was written by the client, read:{0}, written:{1}",
          resp.val, currTransaction.val
        );
      goto SendWriteTransaction;
    }

    on eTimeOut do {
      send coordinator, eReadTransReq, (client=this, key=currTransaction.key);
    }
  }
}

// implemented as a foreign function
// returns a named_tuple with the following fields:
// - key: str stringified random int(1, 10)
// - val: int, random int(1,10)
// - uniqueID: int, transaction ID
fun ChooseRandomTransaction(uniqueId: int): tTrans;

module TwoPCClient = {Client};
