#!/bin/bash

source colorized.sh

# Collection of helper functions used in demos.
#
function install_in_container()
{
  # Container image app to install.
  app_name=$1

  CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-podman}

  if [ $app_name == $OS_APP ]; then
    echo "$(info) Deploying the ${OS_APP} backend..."
    echo
    command "$CONTAINER_RUNTIME" run --name "${OS_APP}" -d -p 9200:9200 -p 9600:9600 --network "${NET_NAME}" -e "discovery.type=single-node" -e "DISABLE_INSTALL_DEMO_CONFIG=true" -e "DISABLE_SECURITY_PLUGIN=true" "${OS_IMAGE}":"${OS_VERSION}"
  elif [ $app_name == $OSD_APP ]; then
    echo "$(info) Deploying the ${OSD_APP} frontend..."
    echo
    command "$CONTAINER_RUNTIME" run --name "${OSD_APP}" -d --network "${NET_NAME}" -p 5601:5601 -e "DISABLE_SECURITY_DASHBOARDS_PLUGIN=true" -v ./"${OSD_CONFIG}":/usr/share/"${OSD_APP}"/config/opensearch_dashboards.yml "${OSD_IMAGE}":"${OSD_VERSION}"
  fi

  if [ $? -ne 0 ]; then
    echo
    echo "$(warn) Cleaning up any workloads that might still be running..."
  
    if [ $app_name == $OS_APP ]; then
      command "$CONTAINER_RUNTIME" container stop "${OS_APP}" >/dev/null 2>&1
      command "$CONTAINER_RUNTIME" container rm "${OS_APP}" >/dev/null 2>&1
    elif [ $app_name == $OSD_APP ]; then
      command "$CONTAINER_RUNTIME" container stop "${OSD_APP}" >/dev/null 2>&1
      command "$CONTAINER_RUNTIME" container rm "${OSD_APP}" >/dev/null 2>&1
    fi

    echo "$(warn) Starting fresh workload..."

    if [ $app_name == $OS_APP ]; then
      echo "$(info) Deploying the ${OS_APP} backend..."
      command "$CONTAINER_RUNTIME" run --name "${OS_APP}" -d --network "${NET_NAME}" -p 9200:9200 -p 9600:9600 -e "discovery.type=single-node" -e "DISABLE_INSTALL_DEMO_CONFIG=true" -e "DISABLE_SECURITY_PLUGIN=true"  "${OS_IMAGE}":"${OS_VERSION}"
    elif [ $app_name == $OSD_APP ]; then
      echo "$(info) Deploying the ${OSD_APP} frontend..."
      command "$CONTAINER_RUNTIME" run --name "${OSD_APP}" -d --network "${NET_NAME}" -p 5601:5601 -e "DISABLE_SECURITY_DASHBOARDS_PLUGIN=true" -v ./"${OSD_CONFIG}":/usr/share/"${OSD_APP}"/config/opensearch_dashboards.yml "${OSD_IMAGE}":"${OSD_VERSION}"
    fi

    if [ $? -ne 0 ]; then
      echo
      if [[ $(uname) == "Darwin" ]]; then
        echo
        echo "$(error) ====================================================================================================================="
        echo "$(error) =                                                                                                                   ="
        echo "$(error) =  Error occurred during '$CONTAINER_RUNTIME run' deploying of a workload...                                                    ="
        echo "$(error) =                                                                                                                   ="
        echo "$(error) =  The problem is with the following command, so maybe try it outside this installation script:                     ="
        echo "$(error) =                                                                                                                   ="
    
        if [ $app_name == $OS_APP ]; then
          echo "$(error) =   $ $CONTAINER_RUNTIME run --name ${OS_APP} -d --network ${NET_NAME} -p 9200:9200 -p 9600:9600 -e 'discovery.type=single-node' \  ="
          echo "$(error) =       -e 'DISABLE_INSTALL_DEMO_CONFIG=true' -e 'DISABLE_SECURITY_PLUGIN=true' i                                    \  ="
          echo "$(error) =       ${OS_IMAGE}:${OS_VERSION}               ="
        elif [ $app_name == $OSD_APP ]; then
          echo "$(error) =   $ $CONTAINER_RUNTIME run --name ${OSD_APP} -d --network ${NET_NAME} -p 5601:5601 -e 'DISABLE_SECURITY_DASHBOARDS_PLUGIN=true'       \  ="
          echo "$(error) =       -v ./${OSD_CONFIG}:/usr/share/${OSD_APP}/config/opensearch_dashboards.yml \  ="
          echo "$(error) =       ${OSD_IMAGE}:${OSD_VERSION}                 ="
        fi

        echo "$(error) =                                                                                                                   ="
        echo "$(error) ====================================================================================================================="
        echo
        exit;
      fi

      echo "$(error) Error occurred during '$CONTAINER_RUNTIME run' starting container... make sure your Linux $CONTAINER_RUNTIME installation"
      echo "$(error) is initialized and working correctly before trying this installation script again."
      echo
      exit;
    fi
  fi
}

