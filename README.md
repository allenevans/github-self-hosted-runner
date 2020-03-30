# Github Self-hosted Actions Runner

Dockerized Github self-hosted runner that allows github actions pipelines to be run in a local, self-managed docker container.

Advantages:-
* Control the build environment dependencies, for example use a specific version of terraform
* Does not consume github build minutes
* Good for longer running processes

Disadvantages:-
* Workspaces may not cleaned between runs, this can cause old artifacts to interfere with builds
* Configuring the token currently has to be done via the UI. See [API to generate runners token](https://github.community/t5/GitHub-Actions/API-to-generate-runners-token/m-p/39911/highlight/true#M4012)
* Generated API token is not always correct, if runner is unable to connect, stop the runner, generate a new key and try again.

## Getting started

The fastest way to launch the self-hosted runner is by using docker image from docker hub.

```shell script
export GITHUB_TOKEN=<YOUR GITHUB TOKEN HERE>; 
export REPOSITORY=<YOUR organisation/repository>;

docker run -it --rm -e GITHUB_TOKEN=${GITHUB_TOKEN} -e REPOSITORY=${REPOSITORY} allenevans/github-self-hosted-runner:latest
```

Alternatively check out the `npm` convenience scripts. 

Go to https://github.com/<YOUR organisation/repository>/settings/actions to verify self-hosted runner registration.

## Environment variables
| Variable                | Description                                                                                                                                                                                                          | Required | Default                       |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|-------------------------------|
| GITHUB_API              | Github api base url.                                                                                                                                                                                                 | N        | `https://api.github.com`      |
| GITHUB_TOKEN            | Github API token.<br>[Creating a personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)                                            | Y        |                               |
| GITHUB_URL              | Github base url.                                                                                                                                                                                                     | N        | `https://github.com`          |
| REPOSITORY              | Owner / repository name. For example `allenevans/github-self-hosted-runner`.                                                                                                                                         | Y        |                               |
| RUNNER_NAME             | Name of the self-hosted github action runner. Using a fixed name prevents multiple self-hosted runner registrations.                                                                                                 | N        | ${HOSTNAME} or `local-runner` |
| RUNNER_REPLACE_EXISTING | Automatically replace an existing runner with the same name. `true` or `false`                                                                                                                                       | N        | `true`                        |
| RUNNER_TOKEN            | Runner registration token. Leave blank to request a new registration token when starting.<br>[Create a registration token](https://developer.github.com/v3/actions/self_hosted_runners/#create-a-registration-token) | N        |                               |
| RUNNER_WORK_DIRECTORY   | Working directory used inside the self-hosted runner for checking out code.                                                                                                                                          | N        | `_work`                       |

## NPM Scripts
> Build\
> Build the docker file locally
> ```shell script
> npm run build
> ```

> Start\
> Run the github runner docker container in detached mode
> ```shell script
> GITHUB_TOKEN=... REPOSITORY=... npm start
> ```

> Logs\
> Follow the github runner docker container logs
> ```shell script
> npm run logs
> ```

> Stop\
> Terminate the github runner docker container
> ```shell script
> npm run stop
> ```


## Notes

When using locally hosted github runners, it may be necessary to manually purge the workspace. For example, adding
the following steps into your build pipeline can help to ensure the workspace is clean.

These steps should not be used on github hosted runners since the workspace on these runners will always be clean.

```
jobs:
  build:
    runs-on: self-hosted

  steps:
    # Clear workspace directory. Only do this on self-hosted runners.
    - name: Clean workspace
      run: rm -rf $RUNNER_WORK_DIRECTORY/* || true

    # clear any left over tags from previous builds then get branches and tags
    - name: Clean checkout
      run: |
      for tag in `git tag -l`; do git tag -d $tag; done
      git fetch && git fetch -t && git checkout ${{github.head_ref}}
```
