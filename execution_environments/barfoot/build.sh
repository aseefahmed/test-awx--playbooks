#!/bin/bash

docker build --pull --progress plain --no-cache=true -t registry.barfoot.co.nz/devops/awxee-barfoot:20221215_01 .
docker push  registry.barfoot.co.nz/devops/awxee-barfoot:20221215_01
