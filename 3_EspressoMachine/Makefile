.SILENT:
.DEFAULT_GOAL:=check
.PHONY: compile check clean

PROJ:=EspressoMachine
TEST_CASES:= tcSaneUserUsingCoffeeMachine tcCrazyUserUsingCoffeeMachine

SRCS:=$(wildcard PSrc/*.p PTst/*.p PSpec/*.p )
DLL:=POutput/netcoreapp3.1/$(PROJ).dll

PMC:=coyote test
NUM_SCHEDULES:=10000

$(DLL): $(SRCS)
	pc -proj:$(PROJ).pproj

compile: $(DLL)

check: $(TEST_CASES)

$(TEST_CASES): $(DLL)
	$(PMC) POutput/netcoreapp3.1/$(PROJ).dll -m PImplementation.$@.Execute \
		-i $(NUM_SCHEDULES)

clean:
	git clean -x -d -i
