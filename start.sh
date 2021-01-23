#!/usr/bin/env bash

# function handling signals from Docker
_term() { 
  echo "Caught $1 signal!"
  kill -TERM "$child" 2>/dev/null
  if [[ $1 eq "SIGUSR1" ]];
  then
    echo "Deregestering the runner"
    /runner/config.sh remove --token ${GH_RUNNER_TOKEN}
  else
    echo "NOT deregestering the runner"
  fi
  exit
}

# SIGTERM is the standard signal when container is stopped
# -> keep the runner registered with Github
trap "_term \"SIGTERM\"" SIGTERM

# SIGUSR1 stop container like: docker kill -s SIGUSR1 <container_name>
# -> delete the registration of the runner with Guthub
trap "_term \"SIGUSR1\"" SIGUSR1

# check for runner token to be set in environment
if [[ -z ${GH_RUNNER_TOKEN} ]];
then
    echo "Environment variable 'GH_RUNNER_TOKEN' is not set"
    exit 1
fi

# check for repository URL to be set in envrionment
if [[ -z ${GH_REPOSITORY} ]];
then
    echo "Environment variable 'GH_REPOSITORY' is not set"
    exit 1
fi

# generate random password
# silent fail because it wont be able override password on restart
newPass=$(pwgen -s1 20)
printf "runner\n${newPass}\n${newPass}\n" | passwd 2> /dev/null || echo

# print runner version
echo "github runner version: $(./config.sh --version)"
echo "github runner commit: $(./config.sh --commit)"

workDir=/tmp/_work/$(pwgen -s1 5)

mkdir -p ${workDir}
echo "Runner working directory: ${workDir}"

# can fail if already configured
/runner/config.sh --unattended --url ${GH_REPOSITORY} --token ${GH_RUNNER_TOKEN} --labels ${GH_RUNNER_LABELS} --replace --work ${workDir} || echo

# start runner in background and save pid
/runner/run.sh &
runner_pid=$! 

# wait for the runner to shut down
wait "$runner_pid"
