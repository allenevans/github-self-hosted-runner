FROM debian:bullseye

# https://github.com/docker/compose/releases
ARG DOCKER_COMPOSE_VERSION=2.31.0

# https://github.com/actions/runner/releases
ARG GITHUB_RUNNER_VERSION=2.321.0

# https://github.com/docker/machine/releases
ARG DOCKER_MACHINE_VERSION=0.16.2

# https://www.terraform.io/downloads.html
ARG TERRAFORM_VERSION=1.10.0

ENV GITHUB_URL=""
ENV RUNNER_NAME=""
ENV RUNNER_WORK_DIRECTORY="_work"
ENV RUNNER_TOKEN=""
ENV REPOSITORY=""

# Packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y \
        apt-transport-https \
        autoconf \
        build-essential \
        bzip2 \
        ca-certificates \
        curl \
        curl \
        default-mysql-client \
        git \
        jq \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libatspi2.0-0 \
        libcairo2 \
        libcups2 \
        libgbm1 \
        libglu1-mesa \
        libicu-dev \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libxcomposite1 \
        libxi6 \
        libxkbcommon0 \
        libxrandr2 \
        libxrender1 \
        libxtst6 \
        nasm \
        python \
        python3 \
        python3-pip \
        python3-setuptools \
        software-properties-common \
        sudo \
        supervisor \
        unzip \
        zip; \
        pip install awscli --upgrade

# Install Docker CLI
RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm get-docker.sh

# Install Docker-Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Install docker machine
RUN base=https://github.com/docker/machine/releases/download/v${DOCKER_MACHINE_VERSION} && \
      curl -L $base/docker-machine-$(uname -s)-$(uname -m) > /tmp/docker-machine && \
      install /tmp/docker-machine /bin/docker-machine

# Install terraform
RUN curl -L -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Tidy up
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Permissions
RUN useradd -ms /bin/bash runner && \
    usermod -aG docker runner && \
    usermod -aG sudo runner && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install the github runner
WORKDIR /home/runner
RUN curl -L -O https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz \
    && tar -zxf actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz \
    && rm -f actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz \
    && ./bin/installdependencies.sh \
    && chown -R runner: /home/runner

COPY ./src /
RUN chmod 644 /etc/supervisor/conf.d/supervisord.conf

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

USER runner
