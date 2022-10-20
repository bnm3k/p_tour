.SILENT:
.DEFAULT_GOAL:=check
.PHONY: help compile check clean

pmc:=coyote test
num_schedules:=100


help:
	echo '2 phase commit example'

compile:
	pc -proj:TwoPhaseCommit.pproj

check:
	# check tcSingleClient
	$(pmc) POutput/netcoreapp3.1/ClientServer.dll \
		-m PImplementation.tcSingleClient.Execute -i $(num_schedules)
	# check tcMultipleClients
	$(pmc) POutput/netcoreapp3.1/ClientServer.dll \
		-m PImplementation.tcMultipleClients.Execute -i $(num_schedules)
	# check tcSingleClientAbstractServer
	$(pmc) POutput/netcoreapp3.1/ClientServer.dll \
		-m PImplementation.tcSingleClientAbstractServer.Execute -i $(num_schedules)

clean:
	git clean -x -d -i
