function handler() {
    # needed to ensure that the logs are printed to stderr and show up in the AWS console
    exec 1>&2

    # Event data can be used in the future to trigger different actions
    EVENT_DATA=$1
    echo "Echoing event request: '${EVENT_DATA}'"

    DATABASE_URL_VALUE=$(aws secretsmanager get-secret-value --secret-id $DB_URL_SECRET_ARN --query "SecretString" --output text)
    export DATABASE_URL="${DATABASE_URL_VALUE}?connect_timeout=30&pool_timeout=30"

    echo "Syncing S3 bucket to /tmp/"
    aws s3 sync s3://${DEPLOYMENT_S3_BUCKET_NAME}/ /tmp/

    # Node Modules and Package Json are created in Dockerfile
    cp -a node_modules /tmp/node_modules
    cp -a package.json /tmp/package.json

    # Move to the prisma directory where the filesystem is writeable
    cd /tmp

    # subfolders here should be `prisma` and `flags`

    echo "Running Prisma migration"
    prisma migrate deploy

    echo "Running Prisma generate"
    prisma generate

    echo "Running Prisma seeding script"
    tsx ./prisma/seeds/seed_cli.ts --environment=production

    echo "Running Flag initialization and Privilege Flush"
    tsx ./deployment/initialization.ts

    exit 0
}
