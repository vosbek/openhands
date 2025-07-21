# Universal Development Environment Containerfile
# Multi-stage build for enterprise environments with proxy and certificate support

ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE} as base

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG NPM_REGISTRY=https://registry.npmjs.org/
ARG PIP_INDEX_URL=https://pypi.org/simple/

ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV NO_PROXY=${NO_PROXY}
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

COPY certs/* /usr/local/share/ca-certificates/ 2>/dev/null || true
RUN update-ca-certificates || true

FROM base as java-stage

RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

FROM java-stage as maven-stage

ARG MAVEN_VERSION=3.9.4
ARG MAVEN_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz

RUN wget --progress=dot:giga "${MAVEN_URL}" -O /tmp/maven.tar.gz \
    && tar -xzf /tmp/maven.tar.gz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
    && rm /tmp/maven.tar.gz

ENV MAVEN_HOME=/opt/maven
ENV PATH="${MAVEN_HOME}/bin:${PATH}"

FROM maven-stage as python-stage

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python3 /usr/bin/python

COPY config/pip.conf /etc/pip.conf

RUN python -m pip install --upgrade pip setuptools wheel

FROM python-stage as node-stage

ARG NODE_VERSION=18
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY config/.npmrc /root/.npmrc

RUN if [ -n "${NPM_REGISTRY}" ] && [ "${NPM_REGISTRY}" != "https://registry.npmjs.org/" ]; then \
        npm config set registry "${NPM_REGISTRY}"; \
    fi

RUN if [ -n "${HTTP_PROXY}" ]; then \
        npm config set proxy "${HTTP_PROXY}"; \
    fi

RUN if [ -n "${HTTPS_PROXY}" ]; then \
        npm config set https-proxy "${HTTPS_PROXY}"; \
    fi

FROM node-stage as tools-stage

RUN apt-get update && apt-get install -y \
    git \
    vim \
    nano \
    curl \
    wget \
    unzip \
    zip \
    tree \
    htop \
    jq \
    awscli \
    openssh-client \
    rsync \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://get.docker.com | sh || true

FROM tools-stage as user-stage

ARG USER_UID=1000
ARG USER_GID=1000
ARG USERNAME=developer

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USERNAME}
WORKDIR /home/${USERNAME}

COPY --chown=${USERNAME}:${USERNAME} config/.gitconfig /home/${USERNAME}/.gitconfig.template
COPY --chown=${USERNAME}:${USERNAME} config/.bashrc /home/${USERNAME}/.bashrc
COPY --chown=${USERNAME}:${USERNAME} config/entrypoint.sh /home/${USERNAME}/entrypoint.sh

RUN mkdir -p /home/${USERNAME}/.aws \
    && mkdir -p /home/${USERNAME}/.ssh \
    && mkdir -p /home/${USERNAME}/.local/bin

ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

RUN npm config set prefix "/home/${USERNAME}/.local"

RUN if [ -n "${NPM_REGISTRY}" ] && [ "${NPM_REGISTRY}" != "https://registry.npmjs.org/" ]; then \
        npm config set registry "${NPM_REGISTRY}"; \
    fi

RUN python -m pip install --user \
    jupyterlab \
    boto3 \
    requests \
    black \
    flake8 \
    pytest

ENV JUPYTER_CONFIG_DIR=/home/${USERNAME}/.jupyter
ENV JUPYTER_DATA_DIR=/home/${USERNAME}/.local/share/jupyter

RUN mkdir -p ${JUPYTER_CONFIG_DIR} ${JUPYTER_DATA_DIR}

FROM user-stage as final

VOLUME ["/workspace", "/config", "/cache"]

EXPOSE 8888 3000 8080 5000

COPY --chown=${USERNAME}:${USERNAME} scripts/setup-env.sh /home/${USERNAME}/setup-env.sh
RUN chmod +x /home/${USERNAME}/setup-env.sh /home/${USERNAME}/entrypoint.sh

ENV SHELL=/bin/bash
ENV EDITOR=vim

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8888/ || exit 1

ENTRYPOINT ["/home/developer/entrypoint.sh"]
CMD ["/bin/bash"]

LABEL maintainer="Development Team" \
      version="1.0.0" \
      description="Universal Development Environment with Java, Python, Node.js, and enterprise support" \
      platform="multi-platform" \
      enterprise="true"