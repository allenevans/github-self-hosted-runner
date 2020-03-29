#if [[ -z $REPOSITORY ]]; then
#    echo "Error : You need to set the REPOSITORY environment variable."
#    exit 1
#fi

#RUNNER_TOKEN=${RUNNER_TOKEN:-};
#if [[ -z $RUNNER_TOKEN ]]; then
#  echo "Enter API token ${REPOSITORY_URL}/settings/actions:";
#  read -r RUNNER_TOKEN;
#fi

echo Starting runner "${RUNNER_NAME:-self-hosted}...";
docker-compose up -d
