default:: run
naem=progression
port=9002

#region Commands
build:
	@$(info Build the Docker file)
	@docker build -t $(naem) .

live:
	@$(info Running the Docker file)
	#This exposes port 9000 from the host machine to port 8888 within the docker machine
	@docker run -p $(port):8888 -ti $(naem) /bin/bash

kill:
	@$(info Killing all the Dockerfiles)
	@-docker kill $(naem)
	@-docker rm -f $(naem)
	@-docker rmi -f $(naem)

run:
	@$(info Running the juypter notebook)
	@jupyter lab --ip=127.0.0.1 --port=$(port)
#endregion
