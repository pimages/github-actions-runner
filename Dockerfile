
FROM balenalib/raspberry-pi-debian:latest

ARG GH_ACTIONS_RUNNER_VERSION=2.275.1
ARG PACKAGES="gnupg2 apt-transport-https ca-certificates software-properties-common pwgen git make curl wget zip libicu-dev build-essential libssl-dev"

# install basic stuff
RUN apt-get update \
    && apt-get install -y -q ${PACKAGES} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install docker
RUN apt-get update \
    && apt-get install -y docker.io \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# create "runner" user
RUN useradd -d /runner --uid=1000 runner \
    && echo 'runner:runner' | chpasswd \
    && mkdir /runner \
    && chown -R runner:runner /runner

USER runner
WORKDIR /runner

# install github actions runner
RUN curl -o actions-runner-linux-arm.tar.gz -L https://github.com/actions/runner/releases/download/v${GH_ACTIONS_RUNNER_VERSION}/actions-runner-linux-arm-${GH_ACTIONS_RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-arm.tar.gz \
    && rm -f actions-runner-linux-arm.tar.gz

COPY start.sh /

CMD /start.sh
