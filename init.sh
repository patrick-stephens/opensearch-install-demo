#!/bin/bash

DEMO="OpenSearch Easy Install demo"
AUTHORS="Eric D. Schabell"
PROJECT="git@gitlab.com:o11y-workshops/opensearch-install-demo.git"

# variables used globally in sourced functions.
export WAIT_ON_CONTAINER_START=25
export NET_NAME="os-net"
export OS_APP="opensearch"
export OS_VERSION=3.3.1
export OS_IMAGE="opensearchproject/${OS_APP}"
export OS_PWD="Opensearch@demo1"
export OSD_APP="opensearch-dashboards"
export OSD_VERSION=3.3.0
export OSD_IMAGE="opensearchproject/${OSD_APP}"
export OSD_CONFIG="support/${OSD_APP}.yml"

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
echo "$(info) ##  brought to you by ${AUTHORS}                               ##"
echo "$(info) ##                                                                   ##"   
echo "$(info) ##  ${PROJECT}        ##"
echo "$(info) ##                                                                   ##"   
echo "$(info) #######################################################################"
echo

 # Check the  podman installation.
 echo "$(info) Checking if Podman is installed..."
 command -v podman --version -v  >/dev/null 2>&1 || { echo >&2 "$(error) Podman is required but not installed yet... download and install: https://podman.io/getting-started/installation"; exit; }
 
# Configure network for opensearch containers.
echo "$(info) Creating new network called ${NET_NAME}..."
echo
command podman network rm -f "${NET_NAME}"
command podman network create "${NET_NAME}"

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
echo "$(info) Waiting for ${OS_APP} to start..."

for ((i = 0; i < "${WAIT_ON_CONTAINER_START}"; ++i)); do
  echo "$(info) ..."
  sleep 1
done

echo
echo "$(info) Testing if ${OS_APP} is avialable..."
echo
command curl http://localhost:9200 -ku admin:"${OS_PWD}"

if [ $? -ne 0 ]; then
  echo "$(warn) Error occurred during 'install_in_container' for ${OS_APP}..."
  echo "$(warn)" 
  echo "$(warn) Maybe try to see if it completed now that more time has"
  echo "$(warn) passed by running this commmand on the command line:"
  echo
  echo "$(warn)    command curl http://localhost:9200 -ku admin:${OS_PWD}"
  echo
  exit;
fi

install_in_container "${OSD_APP}"

if [ $? -ne 0 ]; then
  echo "$(error) Error occurred during 'install_in_container' for ${OSD_APP}..."
  echo
  exit;
fi

echo
echo
echo "$(info) =================================================================================================================="
echo "$(info) =                                                                                                                ="
echo "$(info) =  Install complete, get ready to rock OpenSearch!                                                               ="
echo "$(info) =                                                                                                                ="
echo "$(info) =  Attach to the running container images with the following:                                                    ="
echo "$(info) =                                                                                                                ="
echo "$(info) =    $ podman attach ${OS_APP}                                                                                  ="
echo "$(info) =    $ podman attach osd                                                                                         ="
echo "$(info) =                                                                                                                ="
echo "$(info) =  The ${OS_APP} is available at:                                                                               ="
echo "$(info) =                                                                                                                ="
echo "$(info) =    http://localhost:9200  (admin:${OS_PWD})                                                             ="
echo "$(info) =                                                                                                                ="
echo "$(info) =  The ${OSD_APP} is available at:                                                                    ="
echo "$(info) =                                                                                                                ="
echo "$(info) =    http://localhost:5601  (admin:${OS_PWD})                                                             ="
echo "$(info) =                                                                                                                ="
echo "$(info) =  If you stop the containers, they will be removed, so to restart run the following commands:                   ="
echo "$(info) =                                                                                                                ="
echo "$(info) =   $ podman run --name ${OS_APP} -d --network "${NET_NAME}" -p 9200:9200 -p 9600:9600                 \               ="
echo "$(info) =       -e 'discovery.type=single-node' -e 'plugins.security.ssl.http.enabled=false'             \               ="
echo "$(info) =       -e 'plugins.security.disabled=false' OPENSEARCH_INITIAL_ADMIN_PASSWORD=${OS_PWD}  \               ="
echo "$(info) =       ${OS_IMAGE}:${OS_VERSION}                                                                       ="
echo "$(info) =                                                                                                                ="
echo "$(info) =   $ podman run --name osd -d --network "${NET_NAME}" -p 5601:5601 -v                                               \  ="
echo "$(info) =       ./${OSD_CONFIG}:/usr/share/${OSD_APP}/config/opensearch_dashboards.yml \  ="
echo "$(info) =       ${OSD_IMAGE}:${OSD_VERSION}                                                            ="
echo "$(info) =                                                                                                                ="
echo "$(info) =================================================================================================================="
echo

