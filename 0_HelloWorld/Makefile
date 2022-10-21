.SILENT:
.DEFAULT_GOAL:=check
.PHONY: compile check clean

PROJ:=HelloWorld
DLL:=POutput/netcoreapp3.1/$(PROJ).dll

PMC:=coyote test
NUM_SCHEDULES:=10000

$(DLL): HelloWorld.p
	pc -proj:$(PROJ).pproj

compile: $(DLL)

check:
	$(PMC) POutput/netcoreapp3.1/$(PROJ).dll -i $(NUM_SCHEDULES)

clean:
	git clean -x -d -i
