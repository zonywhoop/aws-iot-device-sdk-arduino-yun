#!/bin/bash
APP=$(basename $0)
APPPATH=$(dirname $0)
LIBDIR="AWS-IoT-Python-Library"
YUNBASE="/opt/aws-iot/"

usage() {
  echo "${APP} is used to setup and copy the AWS IoT Python Library to an Arduino Yun"
  echo "${APP} Usage:"
  echo "  ${APP} [-u] 1.1.1.1 YunPassword"
  echo "  Options:"
  echo "    -u : Update Yun - only copy Python lib and bin directories"
  echo ""
  exit 1
}

# Make an ssh call to the YUN
yunssh() {
  ${APPPATH}/utils/yunssh.sh "${YUNIP}" "${YUNPASS}" "${1}"
}
# SCP Files over to the yun
yunscp() {
  ${APPPATH}/utils/yunscp.sh "${YUNIP}" "${YUNPASS}" "${1}" "${2}"
}
# This sub installs the mqtt python lib on the YUN
install-mqtt() {
  yunssh "opkg update && opkg install distribute python-openssl"
  yunssh "easy_install pip"
  yunssh "pip install paho-mqtt"
}
#This sub creates our aws-iot directories on the Yun and copies over the initial certs
create-directories() {
  yunssh "mkdir -p ${YUNBASE}/bin ${YUNBASE}/certs ${YUNBASE}/lib "
  yunscp "${LIBPATH}/certs/*" "${YUNBASE}/certs/"
}
# This sub copies over the aws-iot lib and bin folders
copy-files() {
  yunscp "${LIBPATH}/bin/*" "${YUNBASE}/bin/"
  yunscp "${LIBPATH}/lib/*" "${YUNBASE}/lib/"
}
# Check to make sure we have a valid application and lib directory path available
if [ ! -d "${APPATH}/${LIBDIR}" ]; then
  echo "APPPATH not properly set or ${APPPATH}/${LIBDIR} does not exist or is not accessible"
  exit 1
fi

# If we were not called with enough arguments then show usage
if [ $# -lt 2 ]; then
  usage
fi

# Initialize our vars
YUNIP=""
YUNPASS=""
UPDATE=0

case "$#" in
  2)
    YUNIP=$1
    YUNPASS=$2
    ;;
  3)
    case "$1" in
      -u)
        UPDATE=1
        ;;
      *)
        usage
        ;;
    esac
    YUNIP=$2
    YUNPASS=$3
  *)
    usage
    ;;
esac

if [ $UPDATE -eq 0 ]; then
  install-mqtt
  create-directories
fi
copy-files
echo "Done"
