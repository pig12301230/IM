#!/usr/bin/env bash

BRAND=${1:-"guChat"}
ENV=${2:-"dev"}

# Sentry_cli(manual)
SENTRY_URL=https://sentry.pstdsf.com/
AUTH_TOKEN=12bace0d8e1f41e596d9b579736dfc9aa2c852018df7408fb742fa2675061f2d
PROJECT_NAME=guchat_native_ios
DSYM_PATH=./build/ChatRoom.app.dSYM.zip

# check environment
if [ "$ENV" != "dev" ] && [ "$ENV" != "uat" ] && [ "$ENV" != "prod" ];
then
  echo "Invalid environment '${ENV}'!! (only support dev, uat and prod)"
  exit 1
else
  echo "Prepare to build IM for: ${BRAND} ${ENV}"
fi

# remove build directory
rm -r build
# run fastlane by enviroment
if [ "$ENV" == "prod" ]
then
  # 目前沒有 archive dev需求，先丟預設 environment file
  BRAND+="Prod"
  bundle exec fastlane release_UAT --env ${BRAND}
elif [ "$ENV" == "uat" ]
then
  BRAND+="Uat"
  bundle exec fastlane release_UAT --env ${BRAND}
else
  echo "Not support Dev now."

  # bundle exec fastlane release --env dev
fi

