type tTrans = (key: string, val: int, transId: int);
type tWriteTransReq = (client: Client, trans: tTrans);
type tWriteTransResp = (transId: int, status: tTransStatus);
type tReadTransReq = (client: Client, key: string);
type tReadTransResp = (key: string, val: int, transId: int, status: tTransStatus);

enum tTransStatus {
  SUCCESS,
  ERROR,
  TIMEOUT
}

/* Events used by the 2PC clients to communicate with the 2PC coordinator */
// event: write transaction request (client to coordinator)
event eWriteTransReq : tWriteTransReq;
// event: write transaction response (coordinator to client)
event eWriteTransResp : tWriteTransResp;
event eReadTransReq: tReadTransReq;
event eReadTransResp: tReadTransResp; // participant to client

// events used for communication between the coordinator and participants
event ePrepareReq: tPrepareReq; // coord to participant
event ePrepareResp: tPrepareResp; // participant to coord
event eCommitTrans: int; // coord to participant
event eAbortTrans: int; // coord to participant


type tPrepareReq = tTrans;
type tPrepareResp = (participant: Participant, transId:int, status: tTransStatus);

// inform participant about the coordinator
event eInformCoordinator: Coordinator;


/*
*
* The Coordinator:
* - receives write and read transactions from the client.
* - services those txs one by one in the order in which they are received.
* - On receiving a write tx, the coordinator sends prepare request to all the
*   participants and waits for prepare responses from all the participants
* - Based on the responsens, the coordinator either commits the tx or aborts
* - If the coordinator fails to receive agreement from participants in time,
*   then *   it times out and aborts the tx.
* - On receiving a read transaction, the coordinator randomly selects a
*   participant and forwards the read request to that participant.
*
*/

machine Coordinator {
  var participants: set[Participant];
  var currentWriteTransReq: tWriteTransReq;
  var seenTransIds: set[int];
  var timer: Timer;

  start state Init {
    entry (payload: set[Participant]){
      participants = payload;
      timer = CreateTimer(this);
      BroadcastToAllParticipants(eInformCoordinator, this);
      goto WaitForTransactions;
    }
  }

  state WaitForTransactions {
    on eWriteTransReq do (wTrans: tWriteTransReq){
      if (wTrans.trans.transId in seenTransIds){
        send wTrans.client, eWriteTransResp, (transId = wTrans.trans.transId, status=TIMEOUT);
        return;
      }

      currentWriteTransReq = wTrans;
      BroadcastToAllParticipants(ePrepareReq, wTrans.trans);
      StartTimer(timer);
      goto WaitForPrepareResponses;
    }

    on eReadTransReq do (rTrans: tReadTransReq){
      // non-deterministacally pick a participant to read from;
      send choose(participants), eReadTransReq, rTrans;
    }

    // when in this state, it is fine to drop these messages as they are from
    // previous transactions
    ignore ePrepareResp, eTimeOut;
  }

  var countPrepareResponses: int;
  state WaitForPrepareResponses {
    // defer requests, we're going to process transactions sequentially
    defer eWriteTransReq;

    on ePrepareResp do (resp: tPrepareResp) {
      if (currentWriteTransReq.trans.transId == resp.transId){
        if (resp.status == SUCCESS){
          countPrepareResponses = countPrepareResponses + 1;
          if (countPrepareResponses == sizeof(participants)){
            DoGlobalCommit();
            goto WaitForTransactions;
          }
        } else {
          DoGlobalAbort(ERROR);
          goto WaitForTransactions;
        }
        // safe to go back and service the next transaction
      } // else  ignore/drop
    }

    on eTimeOut goto WaitForTransactions with { DoGlobalAbort(TIMEOUT); }

    on eReadTransReq do (rTrans: tReadTransReq) {
      send choose(participants), eReadTransReq, rTrans;
    }

    exit {
      countPrepareResponses = 0;
    }
  }

  fun DoGlobalAbort(respStatus: tTransStatus) {
    // ask all participants to abort and fail the transaction
    BroadcastToAllParticipants(eAbortTrans, currentWriteTransReq.trans.transId);
    send currentWriteTransReq.client, eWriteTransResp, (transId = currentWriteTransReq.trans.transId, status=respStatus);
    if (respStatus != TIMEOUT) CancelTimer(timer);
  }

  fun DoGlobalCommit() {
    BroadcastToAllParticipants(eCommitTrans, currentWriteTransReq.trans.transId);
    send currentWriteTransReq.client, eWriteTransResp, (transId = currentWriteTransReq.trans.transId, status=SUCCESS);
    CancelTimer(timer);
  }

  fun BroadcastToAllParticipants(message: event, payload: any){
    var i: int;
    while (i < sizeof(participants)){
      send participants[i], message, payload;
      i = i + 1;
    }
  }
}
