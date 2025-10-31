#!/bin/bash

source colorized.sh

# Collection of helper functions used in demos.
#
function install_in_container()
{
  # Container image app to install.
  app_name=$1

  echo "$(info) Starting the container image for $app_name..."

  if [ $app_name == $OS_APP ]; then
    echo "$(info) Starting the ${OS_APP} image..."
    echo
    command podman run --name "${OS_APP}" -d -p 9200:9200 -p 9600:9600 --network "${NET_NAME}" -e "discovery.type=single-node" -e "OPENSEARCH_INITIAL_ADMIN_PASSWORD=${OS_PWD}" -e "plugins.security.ssl.http.enabled=false" -e "plugins.security.disabled=false" "${OS_IMAGE}":"${OS_VERSION}"
  elif [ $app_name == $OSD_APP ]; then
    echo "$(info) Starting the ${OSD_APP} image..."
    echo
    command podman run --name osd -d --network "${NET_NAME}" -p 5601:5601 -v ./"${OSD_CONFIG}":/usr/share/"${OSD_APP}"/config/opensearch_dashboards.yml "${OSD_IMAGE}":"${OSD_VERSION}"
  fi

  if [ $? -ne 0 ]; then
    echo
    echo "$(warn) Cleaning up any images that might still be running..."
  
    if [ $app_name == $OS_APP ]; then
      command podman container stop "${OS_APP}" >/dev/null 2>&1
      command podman container rm "${OS_APP}" >/dev/null 2>&1
    elif [ $app_name == $OSD_APP ]; then
      command podman container stop "${OS_APP}" >/dev/null 2>&1
      command podman container rm "${OS_APP}" >/dev/null 2>&1
    fi

    echo "$(warn) Starting fresh container image..."

    if [ $app_name == $OS_APP ]; then
      echo "$(info) Starting the ${OS_APP} image..."
      command podman run --name "${OS_APP}" -d --network "${NET_NAME}" -p 9200:9200 -p 9600:9600 -e "discovery.type=single-node" -e "OPENSEARCH_INITIAL_ADMIN_PASSWORD=${OS_PWD}" -e "plugins.security.ssl.http.enabled=false" -e "plugins.security.disabled=false" "${OS_IMAGE}":"${OS_VERSION}"
    elif [ $app_name == $OSD_APP ]; then
      echo "$(info) Starting the ${OSD_APP} image..."
      command podman run --name osd -d --network "${NET_NAME}" -p 5601:5601 -v ./"${OSD_CONFIG}":/usr/share/"${OSD_APP}"/config/opensearch_dashboards.yml "${OSD_IMAGE}":"${OSD_VERSION}"
    fi

    if [ $? -ne 0 ]; then
      echo
      if [[ $(uname) == "Darwin" ]]; then
        echo
        echo "$(error) ====================================================================================================================="
        echo "$(error) =                                                                                                                   ="
        echo "$(error) =  Error occurred during 'podman run' starting of a container...                                                    ="
        echo "$(error) =                                                                                                                   ="
        echo "$(error) =  The problem is with the following command, so maybe try it outside this installation script:                     ="
        echo "$(error) =                                                                                                                   ="
    
        if [ $app_name == $OS_APP ]; then
          echo "$(error) =   $ podman run --name ${OS_APP} -d --network "${NET_NAME}" -p 9200:9200 -p 9600:9600 -e 'discovery.type=single-node' \  ="
          echo "$(error) =       -e 'plugins.security.ssl.http.enabled=false' -e 'plugins.security.disabled=false'                        \  =" 
          echo "$(error) =       OPENSEARCH_INITIAL_ADMIN_PASSWORD=${OS_PWD} ${OS_IMAGE}:${OS_VERSION}                       ="
        elif [ $app_name == $OSD_APP ]; then
          echo "$(error) =   $ podman run --name osd -d --network "${NET_NAME}" -p 5601:5601                                                     \  ="
          echo "$(error) =       -v ./${OSD_CONFIG}:/usr/share/${OSD_APP}/config/opensearch_dashboards.yml \  ="
          echo "$(error) =       ${OSD_IMAGE}:${OSD_VERSION}                                                               ="
        fi

        echo "$(error) =                                                                                                                   ="
        echo "$(error) ====================================================================================================================="
        echo
        exit;
      fi

      echo "$(error) Error occurred during 'podman run' starting container... make sure your Linux podman installation"
      echo "$(error) is initialized and working correctly before trying this installation script again."
      echo
      exit;
    fi
  fi
}

