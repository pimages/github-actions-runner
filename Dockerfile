# basic runner image with (almost) nothing installed
# image name: pimages/github-actions-runner

FROM balenalib/raspberry-pi-debian:latest

ARG GH_ACTIONS_RUNNER_VERSION=2.275.1
ARG PACKAGES="ca-certificates pwgen git"

# install packages
RUN apt-get update \
    && apt-get install -y -q ${PACKAGES} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# create "runner" user
RUN useradd -d /runner --uid=1000 runner \
    && groupmod -g 125 docker \
    && usermod -a -G docker runner \
    && echo 'runner:runner' | chpasswd \
    && mkdir /runner \
    && chown -R runner:runner /runner

USER runner
WORKDIR /runner

# install github actions runner
RUN curl -o actions-runner-linux-arm.tar.gz -L http://172.17.0.1/actions-runner-linux-arm-${GH_ACTIONS_RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-arm.tar.gz \
    && rm -f actions-runner-linux-arm.tar.gz

COPY start.sh /

ENTRYPOINT ["/bin/bash", "/start.sh" ]
