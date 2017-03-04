# educationhistory.lib.unb.ca
## Site repository.

educationhistory.lib.unb.ca site build repository.

## Getting Started
### Requirements
The following packages are required to be globally installed on your development instance:

* [docker](https://www.docker.com)/[docker-compose](https://docs.docker.com/compose/) - An installation HowTo for OSX and Linux [is located here, in section 2.](https://github.com/unb-libraries/docker-drupal/wiki/2.-Setting-Up-Prerequisites).
* [nodejs](https://nodejs.org/en/)
* [JDK 8](http://www.oracle.com/technetwork/java/javase/downloads/index.html)

### 1. Initial Setup

#### A. Configure Local Development
In the ```env/drupal.env``` file, change the environment settings to match your local development environment.

```
DOCKER_ENDPOINT_IP=192.168.99.100
LOCAL_USER_GROUP=20
```

* ```DOCKER_ENDPOINT_IP``` - This is the IP of your docker daemon. In OSX, this is likely the [IP of your docker-machine](https://docs.docker.com/machine/reference/ip/). On Linux, this is probably localhost.
* ```LOCAL_USER_GROUP``` - The [group id](https://kb.iu.edu/d/adwf) of your local user. This is used to change permissions when deploying locally.

#### B. Setup Repository
```
npm install
npm run setup
```

### 2. Deploy Instance
```
npm run start
```

### Other useful commands
* ```clean``` : Clean up typically created files by node and other scripts.
* ```container-shell``` : Opens a /sh prompt into the container.
* ```destroy``` :  Alias for instance-destroy.
* ```instance-destroy``` :  Destroys the local instance and removes container and data.
* ```instance-start-over``` : Stops and destroys any running containers, removes data and volumes, leaving the status similar to immediately after node run setup.
* ```instance-start``` : Starts the container and tails the logs.
* ```instance-stop``` : Stops the container.
* ```logs``` : Tails the container logs.
* ```remote-dev-sync``` : Synchronize data from a remote at hostname __devserver.docker.remote__. Create an ssh/.config to control this. Keyless login must be setup, and the user must have access to docker.
* ```repo-start-over``` : Completely start over with development. Destroy the container, delete all files that aren't in HEAD, pull changes from upstream and re-install and re-setup node.
* ```setup``` :  Run a series of setup commands necessary to begin development and deployment of the container.
* ```start-over``` : Alias for instance-start-over.
* ```start``` : Alias for instance-start.
* ```stop``` : Alias for instance-stop.
* ```test-changes``` : Stop the container, destroy the data and attempt re-deployment as described in your current repo state. Commits need not be made.
* ```uli``` : Provide a ULI link into a running container.
* ```validate-php``` : Validate the git-staged changes against Drupal standards.
* ```write-config``` : Write out the container's in-database configuration into ./config-yml for persistence.


## Repository Branches
* `dev` - Core development branch. Deployed to dev when pushed.
* `live` - Deployed to live when pushed.
