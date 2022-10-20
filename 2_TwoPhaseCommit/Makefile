.SILENT:
.DEFAULT_GOAL:=check
.PHONY: compile check clean

PROJ:=TwoPhaseCommit
TEST_CASES:= tcSingleClientNoFailure tcMultipleClientsNoFailure tcMultipleClientsWithFailure

SRCS:=$(wildcard PSrc/*.p PTst/*.p PSpec/*.p PForeign/*.cs)
DLL:=POutput/netcoreapp3.1/$(PROJ).dll

PMC:=coyote test
NUM_SCHEDULES:=10000

$(DLL): $(SRCS)
	pc -proj:TwoPhaseCommit.pproj

compile: $(DLL)

check: $(TEST_CASES)

$(TEST_CASES): $(DLL)
	$(PMC) POutput/netcoreapp3.1/$(PROJ).dll -m PImplementation.$@.Execute \
		-i $(NUM_SCHEDULES)

clean:
	git clean -x -d -i
