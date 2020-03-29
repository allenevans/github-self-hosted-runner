#!/bin/bash

# Ensure Docker socket is owned by docker group
if [[ -e "/var/run/docker.sock" ]]; then
  sudo chgrp docker /var/run/docker.sock
fi

if [[ "$@" == "bash" ]]; then
  exec "$@"
fi

if [ "$GITHUB_TOKEN" = "" ] && [ "$RUNNER_TOKEN" = "" ]; then
  echo "GITHUB_TOKEN environment variable is not set."
  exit 1
fi

if [[ -z $REPOSITORY ]]; then
  echo "Error: REPOSITORY environment variable is not set"
  exit 1
fi

if [ "$RUNNER_TOKEN" = "" ] || [ "$RUNNER_TOKEN" = "null" ]; then
  RUNNER_TOKEN=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" -X POST "${GITHUB_API:-https://api.github.com}/repos/${REPOSITORY}/actions/runners/registration-token" | jq -r '.token')

  if [ "$RUNNER_TOKEN" = "" ] || [ "$RUNNER_TOKEN" = "null" ]; then
    echo "Error: RUNNER_TOKEN environment variable is not set"
    exit 1
  fi
fi

if [[ -z $RUNNER_WORK_DIRECTORY ]]; then
  echo "RUNNER_WORK_DIRECTORY environment variable is not set, using '_work'."
  export RUNNER_WORK_DIRECTORY="_work"
fi

if [[ -z $RUNNER_REPLACE_EXISTING ]]; then
  export RUNNER_REPLACE_EXISTING="true"
fi

CONFIG_INPUT="\n\n\n"
if [ "$(echo $RUNNER_REPLACE_EXISTING | tr '[:upper:]' '[:lower:]')" == "true" ]; then
  CONFIG_INPUT="Y\n\n"
fi

if [[ -f ".runner" ]]; then
  echo "Runner already configured. Skipping config."
else
  echo -ne $CONFIG_INPUT | ./config.sh \
    --url "${GITHUB_URL:-https://github.com}/$REPOSITORY" \
    --token "$RUNNER_TOKEN" \
    --name "${RUNNER_NAME:-${HOSTNAME:-local-runner}}" \
    --work "$RUNNER_WORK_DIRECTORY"
fi

exec "$@"
