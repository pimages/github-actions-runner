#!/usr/bin/env bash

_term() { 
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
  /runner/config.sh remove --token ${GH_RUNNER_TOKEN}
  exit
}

trap _term SIGTERM

if [[ -z ${GH_RUNNER_TOKEN} ]];
then
    echo "Environment variable 'GH_RUNNER_TOKEN' is not set"
    exit 1
fi

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
