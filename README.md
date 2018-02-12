# Docker S3 Command

## Secrets

To authorize the container with AWS, mount secrets with the names:

- Use `awsKey` to mount your aws key
- Use `awsSecret` to mount your aws secret
- Use `awsSecurityToken` to mount your aws security token (optional)

to the /run/secrets folder

## Environment Variables

Additional AWS parameters can be set using environment variables:

- Use `S3_HOST_BASE` to specify the region of the bucket (optional)
- Use `S3_BUCKET_PATH` to specify the path to the s3 bucket (e.g. s3://mybucket/folder/) (required)
- Use `CRON_SCHEDULE` to specify the cron schedule when performing in cron mode. (e.g. 0 1 * * *)

## Commands
The container can be setup to perform a one time sync from or to s3, or perform scheduled syncs to or from s3 using cron.

- `sync-local-to-s3` Performs a one time sync to s3
- `sync-s3-to-local` Performs a one time sync from s3
- `cron sync-local-to-s3` Performs scheduled sync to as per the `CRON_SCHEDULE` environment variable.
- `cron sync-s3-to-local` Performs scheduled sync from as per the `CRON_SCHEDULE` environment variable.

## Example Compose File

The following example demonstrates how to perform a scheduled sync every minute.

```
version: '3.4'
secrets:
  awsKey:
    file: ./secrets/awsKey
  awsSecret:
    file: ./secrets/awsSecret
services:
  docker-s3cmd:
    image: 'threevl/docker-s3cmd'
    build:
      context: '.'
      dockerfile: 'Dockerfile'
    command: ['cron', 'sync-local-to-s3']
    secrets:
      - awsKey
      - awsSecret
    volumes:
      - ./samples:/opt/src
    environment:
      - "CRON_SCHEDULE=* * * * *"
      - "S3_BUCKET_PATH=s3://canvet-backups/uploads-backup/"
```