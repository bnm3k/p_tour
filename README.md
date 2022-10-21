# P Tutorial

## Introduction

As per the website:

> P is a state machine based programming language for formally modeling and
> specifying complex distributed systems. P allows programmers to model their
> system design as a collection of communicating state machines.

## Contents

Workthrough of P's tutorials and exercises:

1. Client/Server
2. Two Phase Commit
3. Espresso Machine
4. Failure Detector

## Notes on P from the docs

- A P program is a collection of concurrently executing state machines that
  communicate with each other by sending events asynchronously
- Each P state machine has an unbounded FIFO buffer associated with it.
- A `send` consists of asynchronously adding an event with a given payload into
  the FIFO buffer of the target machine
- Each state in the P state machine has an entry function associated with it
  which gets executed when the state machine enters that state
- Upon dequeuing an event from the input queue of the machine, the attached
  handler is executed which might transition the machine to a different state.
- Sends are reliable, buffered, non-blocking and directed. Hence, message loss
  has to be modelled explicitly.
- Events sent by the same machien will always appear in the same order at the
  target state machine. Arbitrary message re-ordering from the same sender has
  to be explcitly modeled in P.
- Specifications are written as global runtime monitors that can observe the
  given events and assert any global safety or liveness invariants.
- In specifications, states marked as `hot` imply that once the execution is
  complete, the monitor should not be in that state, i.e. it is an immediate
  state and on completion, if the machine is still in that state then there's an
  error.
