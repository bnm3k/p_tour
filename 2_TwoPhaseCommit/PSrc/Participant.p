/*
Each participant maintains a local key-value store which is updated based on the
transactions committed by the coordinator. On receiving a prepare request from
the coordinator, the participant chooses to either accept or reject the tx
*/


machine Participant {
  var kvStore: map [string, tTrans];
  var pendingWriteTrans: map[int, tTrans]; // txs that have not been committed or aborted yet
  var coordinator: Coordinator;


  start state Init {
    on eInformCoordinator goto WaitForRequests with (coord: Coordinator){
      coordinator = coord;
    }
    defer eShutDown;
  }

  state WaitForRequests {
    on eAbortTrans do (transId: int) {
      pendingWriteTrans -= (transId);
    }

    on eCommitTrans do (transId: int) {
      kvStore[pendingWriteTrans[transId].key] = pendingWriteTrans[transId];
      pendingWriteTrans -= (transId);
    }

    on ePrepareReq do (req: tPrepareReq) {
      pendingWriteTrans[req.transId] = req;
      // non-deterministically pick whether to accept or reject the transaction
      // the transaction is accepted if one of the two is true:
      //  (1) first time writing key
      //  (2) if key was already present, and the update's transId is greater
      //      than the current transId. This implies that a key's transId is
      //      is strictly monotonic.
      if (! (req.key in kvStore) || (req.key in kvStore && req.transId > kvStore[req.key].transId)){
        send coordinator, ePrepareResp, (participant = this, transId = req.transId, status = SUCCESS);
      }else {
        send coordinator, ePrepareResp, (participant = this, transId = req.transId, status = ERROR);
      }
    }

    on eReadTransReq do (req: tReadTransReq) {
      if (req.key in kvStore){
        send req.client, eReadTransResp, (key=req.key, val=kvStore[req.key].val, transId=kvStore[req.key].transId, status=SUCCESS);
      } else {
        send req.client, eReadTransResp, (key="", val=-1, transId=-1, status=ERROR);
      }
    }

    on eShutDown do {
      raise halt;
    }
  }
}
