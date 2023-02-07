#!/usr/bin/env bash
set -ue

PROJECT_ROOT=/opt/services/vaultwarden

BACKUP_DIR_NAME=backup-`date '+%Y%m%d-%H%M%S'`
BACKUP_DIR_PATH=${PROJECT_ROOT}/_backup/${BACKUP_DIR_NAME}
BACKUP_TAR_PATH=${PROJECT_ROOT}/_backup/${BACKUP_DIR_NAME}.tar.gz
BUCKET=YOUR_BUCKET_NAME_HERE
SERVICE_ACCOUNT_FILE=${PROJECT_ROOT}/service_account.json


PATH=${PATH}:/usr/local/bin # without this gsutil doesn't work in cron

cd ${PROJECT_ROOT}
mkdir -p ${BACKUP_DIR_PATH}

# YOU MAY NEED TO CHANGE TO `docker-compose` DEPENDING ON THE DOCKER VERSION YOU'RE USING
# since we use :latest tag, this will record the current version of docker image we're using
docker compose config --resolve-image-digests > ${BACKUP_DIR_PATH}/docker-compose.yml

# create db backup
sqlite3 vaultwarden_db/db.sqlite3 ".backup '${BACKUP_DIR_PATH}/db.sqlite3'"

# backup data files
cp -R vaultwarden_data ${BACKUP_DIR_PATH}/vaultwarden_data

# backup "sends", this could become huge if you send a lot of files,
# you may need to adjust your bucket retention
# policy to ensure you don't go over the free tier limit
cp -R vaultwarden_sends ${BACKUP_DIR_PATH}/vaultwarden_sends

# create a tar ball
tar -czf ${BACKUP_TAR_PATH} ${BACKUP_DIR_PATH}

# clean up backup folder
rm -rf ${BACKUP_DIR_PATH}

# activate service account
gcloud auth activate-service-account --key-file ${SERVICE_ACCOUNT_FILE}

# upload to bucket
gsutil cp ${BACKUP_TAR_PATH} gs://${BUCKET}

# clean up tar ball
rm ${BACKUP_TAR_PATH}
