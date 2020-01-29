ARG ORACLE_VERSION=8
ARG GO_VERSION=go1.13.7

#
# Building go from source because the latest version available via dnf is 1.12.8
#
FROM kcacciatore/basedevcontainer
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=local
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ARG ORACLE_VERSION=8
ARG GO_VERSION=go1.13.7
ARG corp_http_proxy=http://www-proxy-adcq7.us.oracle.com:80

USER root  
RUN \
  set -eux; \
  export http_proxy=${corp_http_proxy}; \
  export https_proxy=${corp_http_proxy};


RUN dnf install -y golang

LABEL \
    org.opencontainers.image.authors="quentin.mcgaw@gmail.com" \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.url="https://github.com/kcacciatore/godevcontainer" \
    org.opencontainers.image.documentation="https://github.com/kcacciatore/godevcontainer" \
    org.opencontainers.image.source="https://github.com/kcacciatore/godevcontainer" \
    org.opencontainers.image.title="Go Dev container" \
    org.opencontainers.image.description="Go development container for Visual Studio Code Remote Containers development"

# Go build
RUN mkdir -p /opt/go
WORKDIR /opt/go
RUN git clone https://go.googlesource.com/go goroot
WORKDIR /opt/go/goroot 
RUN git checkout $GO_VERSION
WORKDIR /opt/go/goroot/src

RUN /opt/go/goroot/src/all.bash

RUN cp -r /opt/go/goroot/bin/go /usr/local/go
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH
WORKDIR $GOPATH
RUN chown ${USERNAME}:${USER_GID} $GOPATH && \
    chmod 777 $GOPATH

# Shell setup
COPY --chown=${USER_UID}:${USER_GID} shell/.zshrc-specific shell/.welcome.sh /home/${USERNAME}/
COPY shell/.zshrc-specific shell/.welcome.sh /root/
# Install Go packages
RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /bin -d v1.22.2
ENV GO111MODULE=on
RUN go get -v golang.org/x/tools/gopls && \
    chown ${USERNAME}:${USER_GID} /go/bin/* && \
    chmod 500 /go/bin/* && \
    rm -rf /go/pkg /go/src/* /root/.cache/go-build

USER ${USERNAME}
