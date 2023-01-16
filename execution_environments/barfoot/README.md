# Barfoot execution environment for awx

Since the default execution environment does not have many dependencies we need, this docker image provides them.
In order to build it you can use the `build.sh` script, however do not forget to Barfoot docker registry at 
`registry.barfoot.co.nz` with an account that has write access to the `devops` folder.

User `registry.barfoot.co.nz/devops/awxee-barfoot` in the AWX execution environment interface to point to this image.

A kubernetes PersistentVolume object definition to persist data between the runs of execution environments should be provisioned during the cluster deployment.

`pod-spec-override.yaml` - is a Pod spec override for the `barfoot` execution environment that makes use of the persistant data (`/runner/data`)
