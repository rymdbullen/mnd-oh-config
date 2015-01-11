#!/bin/bash
#
# this script needs a config file with the following parameters:
# REMOTE_DIR="<openhab-config-dir>"
# USER=<openhab-username>
# HOST=<openhab-ip-address>
# IPCAM_FIX_URL="<url of ipcam_fix>"
# IPCAM_DYN_URL="<url of ipcam_dyn>"
# MQTT_USER="mqtt username"
# MQTT_PWD="mqtt password"
#

# Setting up a staging area
TEMP_DIR=`mktemp -d`

TARGET=${1:-notspecified}
if [ "${TARGET}" == "notspecified" ]; then
    if [ -f target_env ]; then
        source target_env
    fi
fi
echo "${TARGET}" | grep --extended-regexp "hus1|mnd|local" > /dev/null
TARGET_VERIFIED=$?
if [[ ! $TARGET_VERIFIED -eq 0 ]]; then
    echo "Target '${TARGET}' does not exist, exiting!"
    exit 1
fi
CONFIG_FILE="../cool.cfg@${TARGET}"
if [ ! -f $CONFIG_FILE ]; then
  echo "${CONFIG_FILE} doesn't exist"
  exit 1
fi
source $CONFIG_FILE

SSH_CMD='ssh '
LOCAL_DIR="./configurations"
CONNECTION="${USER}@${HOST}"

if [ ! -d $LOCAL_DIR/persistence ]; then
  echo "${LOCAL_DIR}/persistence doesn't exist"
  exit 1
fi
if [ ! -d $LOCAL_DIR/rules ]; then
  echo "${LOCAL_DIR}/rules doesn't exist"
  exit 1
fi
if [ ! -d $LOCAL_DIR/sitemaps ]; then
  echo "${LOCAL_DIR}/sitemaps doesn't exist"
  exit 1
fi
if [ ! -f $LOCAL_DIR/openhab.cfg ]; then
  echo "${LOCAL_DIR}/openhab.cfg doesn't exist"
  exit 1
fi

echo "Config for the connection: $CONNECTION" >&2
echo "Config for the IPCAM_FIX_URL: $IPCAM_FIX_URL" >&2
echo "Config for the IPCAM_DYN_URL: $IPCAM_DYN_URL" >&2

git pull

# copy to staging dir
echo "copy to staging dir '$TEMP_DIR'"
rsync -avz --quiet --exclude '.git' "$LOCAL_DIR" "$TEMP_DIR"

function replace() {
    langRegex='(.*)=\"(.*)"'
    if [[ ! $1 == \#* ]]; then
        if [[ $1 =~ $langRegex ]]; then
           RE1=${BASH_REMATCH[1]}
           RE2=${BASH_REMATCH[2]}
           RE2=${RE2//[\/]/\\/}
           RE2=${RE2//[\&]/\\&}

#           echo "find $TEMP_DIR -type f -print0 | xargs -0 sed -i \"s/@@${RE1}@@/${RE2}/g\""
           find $TEMP_DIR -type f -print0       | xargs -0 sed -i  "s/@@${RE1}@@/${RE2}/g"
        fi 
    fi 
}

while read p; do
    replace $p
done <$CONFIG_FILE


echo "Executing: rsync -avz --exclude '.git' -e $SSH_CMD \"$TEMP_DIR\" $CONNECTION:\"$REMOTE_DIR\""
rsync -avz --exclude '.git' -e $SSH_CMD "$TEMP_DIR/" $CONNECTION:"$REMOTE_DIR"

#echo "rsync -avz --exclude '.git' -e ${SSH_CMD} \"${LOCAL_DIR}/../webapps/\" ${CONNECTION}:\"${REMOTE_DIR}/../webapps/\""
#echo "${LOCAL_DIR}/../webapps/"
rsync -avz --exclude '.git' -e ${SSH_CMD} "${LOCAL_DIR}/../webapps/" ${CONNECTION}:"${REMOTE_DIR}/../webapps/"

rm -rf $TEMP_DIR
