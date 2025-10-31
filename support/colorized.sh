COLOR_OFF='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

function info()
{
    echo -e "${BLUE}"'[INFO]  ' "$@" "${COLOR_OFF}"
}

function warn()
{
    echo -e "${YELLOW}"'[WARN]  ' "$@" "${COLOR_OFF}" 
}

function error()
{
    echo -e "${RED}"'[ERROR]  ' "$@" "${COLOR_OFF}" 
}
