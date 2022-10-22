.SILENT:
.DEFAULT_GOAL:=check
.PHONY: compile check clean

PROJ:=HelloWorld
DLL:=POutput/netcoreapp3.1/$(PROJ).dll

PMC:=coyote test
NUM_SCHEDULES:=10000

$(DLL): src/HelloWorld.p
	pc -proj:$(PROJ).pproj

compile: $(DLL)

check: $(DLL)
	$(PMC) POutput/netcoreapp3.1/$(PROJ).dll -i $(NUM_SCHEDULES)

.PHONY: create-output-soft-link clear-output
create-output-soft-link:
	ln -s POutput/netcoreapp3.1/Output/HelloWorld.dll/CoyoteOutput/ output

clear-output:
	rm POutput/netcoreapp3.1/Output/HelloWorld.dll/CoyoteOutput/*

clean:
	git clean -x -d -i
	rm output
