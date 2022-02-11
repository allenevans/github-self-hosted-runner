#!/bin/bash

echo

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
else
  echo "GITHUB_TOKEN is set"
fi

if [[ -z $REPOSITORY ]]; then
  echo "Error: REPOSITORY environment variable is not set"
  exit 1
else
  echo "REPOSITORY=${REPOSITORY}"
fi

if [ "$RUNNER_TOKEN" = "" ] || [ "$RUNNER_TOKEN" = "null" ]; then
  echo "RUNNER_TOKEN requested from github"
  RUNNER_TOKEN=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" -X POST "${GITHUB_API:-https://api.github.com}/repos/${REPOSITORY}/actions/runners/registration-token" | jq -r '.token')

  if [ "$RUNNER_TOKEN" = "" ] || [ "$RUNNER_TOKEN" = "null" ]; then
    echo "Error: RUNNER_TOKEN environment variable is not set"
    exit 1
  else
    echo "RUNNER_TOKEN acquired"
  fi
else
  echo "RUNNER_TOKEN is set"
fi

if [[ -z $RUNNER_WORK_DIRECTORY ]]; then
  echo "RUNNER_WORK_DIRECTORY environment variable is not set, using '_work'."
  export RUNNER_WORK_DIRECTORY="_work"
fi
echo "RUNNER_WORK_DIRECTORY=${RUNNER_WORK_DIRECTORY}"

echo "RUNNER_NAME=${RUNNER_NAME:-${HOSTNAME:-local-runner}}"

chmod 666 /var/run/docker.sock || true

if [[ -f ".runner" ]]; then
  echo "Runner already configured. Skipping config."
else
  ./config.sh \
    --unattended \
    --replace \
    --url "${GITHUB_URL:-https://github.com}/$REPOSITORY" \
    --token "$RUNNER_TOKEN" \
    --name "${RUNNER_NAME:-${HOSTNAME:-local-runner}}" \
    --work "$RUNNER_WORK_DIRECTORY"
fi

exec "$@"
