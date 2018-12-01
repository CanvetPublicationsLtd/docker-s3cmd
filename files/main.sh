#!/bin/bash

#
# main entry point to run s3cmd
#
S3CMD_PATH=/opt/s3cmd/s3cmd

if [ -f /run/secrets/awsKey ]; then
    AWS_KEY=`cat /run/secrets/awsKey`
else
    echo "The awsKey secret is missing"
    exit 1
fi

if [ -f /run/secrets/awsSecret ]; then
    AWS_SECRET=`cat /run/secrets/awsSecret`
else
    echo "The awsSecret secret is missing"
    exit 1
fi

if [ -f /run/secrets/awsSecurityToken ]; then
    AWS_SECURITY_TOKEN=`cat /run/secrets/awsSecurityToken`
fi

rm -f /root/.s3cfg

#
# Replace key and secret in the /.s3cfg file with the one the user provided
#
echo "" >> /.s3cfg
echo "access_key = ${AWS_KEY}" >> /.s3cfg
echo "secret_key = ${AWS_SECRET}" >> /.s3cfg

if [ -z "${AWS_SECURITY_TOKEN}" ]; then
    echo "security_token = ${AWS_SECURITY_TOKEN}" >> /.s3cfg
fi


#
# Add region base host if it exist in the env vars
#
if [ "${S3_HOST_BASE}" != "" ]; then
  sed -i "s/host_base = s3.amazonaws.com/# host_base = s3.amazonaws.com/g" /.s3cfg
  echo "host_base = ${S3_HOST_BASE}" >> /.s3cfg
fi

if [ -z "${S3_BUCKET_PATH}" ]; then

    echo "The S3_BUCKET_PATH environment variable is missing"
    exit 1

fi

cp /.s3cfg /root/

if [ "$1" = "cron" ]; then

    if [ -z "$2" ]; then

        echo "The cron command must be run with a second argument specifying the command that will be run"
        exit 1

    fi

    if [ -z "${CRON_SCHEDULE}" ]; then

        echo "The CRON_SCHEDULE environment variable is missing"
        exit 1

    fi

    echo "Setting up cron"

    rm -f /etc/cron.d/root

    mkdir -p /etc/cron.d

    touch /var/log/cron.log

    printf "SHELL=/bin/bash\n# min hour day month weekday command\n${CRON_SCHEDULE} /opt/main.sh $2 ${S3_BUCKET_PATH} >> /var/log/cron.log 2>&1\n# An empty line is required at the end of this file for a valid cron file." >> /etc/cron.d/root

    /usr/sbin/crond -S -l 0 -c /etc/cron.d

    echo "Cron is running"

    tail -f /var/log/cron.log

elif [ "$1" = "sync-s3-to-local" ]; then

    SYNC_PATH=$S3_BUCKET_PATH

    if [ ! -z $3 ]; then

        SYNC_PATH=$3
    fi

    echo "Syncing s3 to local path ${SYNC_PATH}"

    ${S3CMD_PATH} --config=/.s3cfg  sync $SYNC_PATH /opt/dest/

elif [ "$1" = "sync-local-to-s3" ]; then

    SYNC_PATH=$S3_BUCKET_PATH

    if [ ! -z $3 ]; then

        SYNC_PATH=$3
    fi

    echo "Syncing local path ${SYNC_PATH} to s3"
    ${S3CMD_PATH} --config=/.s3cfg sync /opt/src/ $SYNC_PATH

fi