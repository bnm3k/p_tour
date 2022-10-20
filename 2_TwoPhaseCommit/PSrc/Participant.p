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
      // accept if key not in store or if key in store but its transId is less
      // than the request's transId
      if (! (req.key in kvStore) || (req.key in kvStore && req.transId > kvStore[req.key].transId)){
        send coordinator, ePrepareResp, (participant = this, transId = req.transId, status = SUCCESS);
      }else {
        send coordinator, ePrepareResp, (participant = this, transId = req.transId, status = ERROR);
      }
    }

    on eReadTransReq do (req: tReadTransReq) {
      if (req.key in kvStore){
        send req.client, eReadTransResp, (key=req.key, val = kvStore[req.key].val, status = SUCCESS );
      } else {
        send req.client, eReadTransResp, (key="", val=-1, status=ERROR);
      }
    }

    on eShutDown do {
      raise halt;
    }
  }
}
