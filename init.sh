#!/bin/bash

DEMO="OpenSearch Easy Install demo"
AUTHORS="Eric D. Schabell, Patrick Stephens"
# PROJECT="git@gitlab.com:o11y-workshops/opensearch-install-demo.git"
PROJECT="git@github.com:patrick-stephens/opensearch-install-demo.git"

# variables used globally in sourced functions.
export MAJ_PODMAN_VERSION=5
export PODMAN_MEM=6144
export WAIT_ON_CONTAINER_START=20
export NET_NAME="os-net"
export OS_APP="opensearch"
export OS_VERSION=3.3.1
export OS_IMAGE="opensearchproject/${OS_APP}"
export OS_PWD="Opensearch@demo1"
export OSD_APP="opensearch-dashboards"
export OSD_VERSION=3.3.0
export OSD_IMAGE="opensearchproject/${OSD_APP}"
export OSD_CONFIG="support/${OSD_APP}.yml"

export CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-podman}
if [[ $# -gt 0 ]]; then
  if [[ "$1" == "podman" || "$1" == "docker" ]]; then
    CONTAINER_RUNTIME=$1
  else
    echo "$(warn) Container runtime passed in as an argument is not valid, defaulting to podman..."
  fi
fi

# importing functions.
source ./support/functions.sh
source ./support/colorized.sh

# wipe screen.
clear

echo
echo "$(info) #######################################################################"
echo "$(info) ##                                                                   ##"   
echo "$(info) ##  Setting up the ${DEMO}                      ##"
echo "$(info) ##                                                                   ##"   
echo "$(info) ##     ###  ####  ##### #   #  #### #####  ###  ####   #### #   #    ##"
echo "$(info) ##    #   # #   # #     ##  # #     #     #   # #   # #     #   #    ##"
echo "$(info) ##    #   # ####  ###   # # #  ###  ###   ##### ####  #     #####    ##"
echo "$(info) ##    #   # #     #     #  ##     # #     #   # #  #  #     #   #    ##"
echo "$(info) ##     ###  #     ##### #   # ####  ##### #   # #   #  #### #   #    ##"
echo "$(info) ##                                                                   ##"
echo "$(info) ##                       #####  ###   #### #   #                     ##"
echo "$(info) ##                       #     #   # #      # #                      ##"
echo "$(info) ##                       ###   #####  ###    #                       ##"
echo "$(info) ##                       #     #   #     #   #                       ##"
echo "$(info) ##                       ##### #   # ####    #                       ##"
echo "$(info) ##                                                                   ##"
echo "$(info) ##               ##### #   #  #### #####  ###  #     #               ##"
echo "$(info) ##                 #   ##  # #       #   #   # #     #               ##"
echo "$(info) ##                 #   # # #  ###    #   ##### #     #               ##"
echo "$(info) ##                 #   #  ##     #   #   #   # #     #               ##"
echo "$(info) ##               ##### #   # ####    #   #   # ##### #####           ##"
echo "$(info) ##                                                                   ##"   
echo "$(info) ##  brought to you by ${AUTHORS}             ##"
echo "$(info) ##                                                                   ##"   
echo "$(info) ##  ${PROJECT}      ##"
echo "$(info) ##                                                                   ##"   
echo "$(info) #######################################################################"
echo

if [[ "$CONTAINER_RUNTIME" == "podman" ]]; then
  echo "$(info) Using Podman as the container runtime for this installation demo..."
  # Check the podman installation.
  echo "$(info) Checking if Podman is installed..."
  command -v podman --version -v  >/dev/null 2>&1 || { echo >&2 "$(error) Podman is required but not installed yet... download and install: https://podman.io/getting-started/installation"; exit; }
  
  echo "$(info) Checking for Podman version..."
  maj_version=$(podman --version | cut -d" " -f3 | cut -d "." -f1)

  if [ "${maj_version}" -ge "${MAJ_PODMAN_VERSION}" ]; then
    echo "$(info) Installed Podman version is v${maj_version}..."
  else
    echo "$(error) Your Podman version is ${maj_version}, it must be ${MAJ_PODMAN_VERSION}.x or higher, please upgrade..."
    echo
    exit;
  fi

  # Check if podman running.
  echo "$(info) Checking for running Podman machine instance..."
  current_status=$(podman machine inspect | grep State | tr -d ' ' | tr -d ','  | cut -d ':' -f2 | tr -d '"')

  if [ $current_status == "stopped" ]; then
    echo
    echo "$(error) There is currently no Podman machine instance running..." 
    echo "$(error) Please start an existing Podman machine, ensuring it has the minimum memory for this demo as follows:" 
    echo "$(error)"
    echo "$(error)    $ podman machine set --memory ${PODMAN_MEM}"
    echo "$(error)    $ podman machine start"
    echo
    echo "$(warn)  Or if a new Podman machine needs to be created, please use the minumum settings as follows:"
    echo "$(warn)"
    echo "$(warn)     $ podman machine init --memory ${PODMAN_MEM}"
    echo "$(warn)     $ podman machine start"
    echo
    exit;
  fi

  # Check podman machine memory check.
  echo "$(info) Checking for minimum Podman machine memory sizing for installation..."
  current_setting=$(podman machine inspect | grep Memory | tr -d ' ' | cut -d ':' -f2 | cut -d ',' -f1)

  if [[ "$current_setting" -lt "${PODMAN_MEM}" ]]; then
    echo
    echo "$(error) The current memory setting ($current_setting) for Podman machine instance is too low..."
    echo "$(error) Please adjust by stopping the Podman machine, changing the memory, and restarting as follows: "
    echo "$(error)"
    echo "$(error)    $ podman machine stop"
    echo "$(error)    $ podman machine set --memory ${PODMAN_MEM}"
    echo "$(error)    $ podman machine start"
    echo
    exit;
  else
    echo "$(info) Podman machine memory setting found ($current_setting) met the minimum requirements (${PODMAN_MEM})..."
  fi
else
  echo "$(warn) Container runtime is set to ${CONTAINER_RUNTIME}, if this is not intentional, set the environment variable CONTAINER_RUNTIME back to podman and re-run this installation script..."
fi

# Configure network for opensearch containers.
echo "$(info) Creating new network called ${NET_NAME}..."
echo
command "$CONTAINER_RUNTIME" network rm -f "${NET_NAME}"
command "$CONTAINER_RUNTIME" network create "${NET_NAME}"

if [ $? -ne 0 ]; then
  echo "$(error) Error occurred during 'network create' for ${NET_NAME}..."
  echo
  exit;
fi

echo
echo "$(info) Network ${NET_NAME} created..."

install_in_container "${OS_APP}"

if [ $? -ne 0 ]; then
  echo "$(error) Error occurred during 'install_in_container' for ${OS_APP}..."
  echo
  exit;
fi

echo
echo "$(info) Waiting for ${OS_APP} to deploy..."

for ((i = 0; i < "${WAIT_ON_CONTAINER_START}"; ++i)); do
  echo "$(info) ..."
  sleep 1
done

echo
echo "$(info) Testing if ${OS_APP} is available..."
echo
command curl http://localhost:9200 -ku admin:"${OS_PWD}" >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "$(warn) Error occurred during 'install_in_container' for ${OS_APP}..."
  echo "$(warn)" 
  echo "$(warn) Maybe try to see if it completed now that more time has"
  echo "$(warn) passed by running this commmand on the command line:"
  echo
  echo "$(warn)    curl http://localhost:9200 -ku admin:${OS_PWD}"
  echo
  exit;
fi

echo "$(info) Backend ${OS_APP} is available, moving onwards..."

install_in_container "${OSD_APP}"

if [ $? -ne 0 ]; then
  echo "$(error) Error occurred during 'install_in_container' for ${OSD_APP}..."
  echo
  exit;
fi

echo
echo "$(info) ====================================================================================================================="
echo "$(info) =                                                                                                                   ="
echo "$(info) =  Install complete, get ready to rock OpenSearch!                                                                  ="
echo "$(info) =                                                                                                                   ="
echo "$(info) =  Attach to the running container images with the following:                                                       ="
echo "$(info) =                                                                                                                   ="
echo "$(info) =    $ $CONTAINER_RUNTIME attach ${OS_APP}                                                                          ="
echo "$(info) =    $ $CONTAINER_RUNTIME attach ${OSD_APP}                                                                         ="
echo "$(info) =                                                                                                                   ="
echo "$(info) =  The ${OS_APP} is available at:                                                                                   ="
echo "$(info) =                                                                                                                   ="
echo "$(info) =    http://localhost:9200  (admin:${OS_PWD})                                                                       ="
echo "$(info) =                                                                                                                   ="
echo "$(info) =  The ${OSD_APP} is available at:                                                                                  ="
echo "$(info) =                                                                                                                   ="
echo "$(info) =    http://localhost:5601  (admin:${OS_PWD})                                                                       ="
echo "$(info) =                                                                                                                   ="
echo "$(info) =  If you stop the containers, they will be removed, so to restart run the following commands:                      ="
echo "$(info) =                                                                                                                   ="
echo "$(info) =   $ $CONTAINER_RUNTIME run --name ${OS_APP} -d --network "${NET_NAME}" -p 9200:9200 -p 9600:9600               \  ="
echo "$(info) =       -e 'discovery.type=single-node' -e 'DISABLE_INSTALL_DEMO_CONFIG=true' -e 'DISABLE_SECURITY_PLUGIN=true'  \  ="
echo "$(info) =       ${OS_IMAGE}:${OS_VERSION}                                                                                   ="
echo "$(info) =                                                                                                                   ="
echo "$(info) =   $ $CONTAINER_RUNTIME run --name ${OSD_APP} -d --network "${NET_NAME}" -p 5601:5601 -v  -e 'DISABLE_SECURITY_DASHBOARDS_PLUGIN=true'    \  ="
echo "$(info) =       -v ./${OSD_CONFIG}:/usr/share/${OSD_APP}/config/opensearch_dashboards.yml \                                 ="
echo "$(info) =       ${OSD_IMAGE}:${OSD_VERSION}                                                                                 ="
echo "$(info) =                                                                                                                   ="
echo "$(info) ====================================================================================================================="
echo

