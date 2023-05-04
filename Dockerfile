FROM --platform=linux/amd64 python:3.8-alpine AS aws-builder

ENV AWSCLI_VERSION=2.10.1

RUN apk add --no-cache \
    curl \
    make \
    cmake \
    gcc \
    g++ \
    libc-dev \
    libffi-dev \
    openssl-dev \
    && curl https://awscli.amazonaws.com/awscli-${AWSCLI_VERSION}.tar.gz | tar -xz \
    && cd awscli-${AWSCLI_VERSION} \
    && ./configure --prefix=/opt/aws-cli/ --with-download-deps \
    && make \
    && make install

FROM --platform=linux/amd64 alpine:3.17.3 as builder

ARG TERRAFORM_VERSION=1.4.3
ARG KUBECTL_VERSION=1.25.4
ARG JUST_VERSION=1.13.0
ARG GOMPLATE_VERSION=3.11.5
ARG JQ_VERSION=1.6

WORKDIR /binaries

RUN mkdir -p /binaries/bin

# Install terraform
RUN apk update  && \
        apk add curl unzip && \
        curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip && \
        unzip terraform.zip && \
        chmod +x terraform && \
        mv terraform ./bin

# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
        chmod +x ./kubectl && \
        mv kubectl ./bin


# Install just
RUN curl -L https://github.com/casey/just/releases/download/1.13.0/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz -o just.tar.gz && \
        tar -xvf just.tar.gz && \
        chmod +x ./just && \
        mv just ./bin

# Install gomplate
RUN curl -L https://github.com/hairyhenderson/gomplate/releases/download/v${GOMPLATE_VERSION}/gomplate_linux-amd64 -o gomplate && \
        chmod +x ./gomplate && \
        mv gomplate ./bin

# Install jq 
RUN curl -L https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 -o jq && \
        chmod +x ./jq && \
        mv jq ./bin


FROM --platform=linux/amd64 python:3.8-alpine3.17 as final

RUN apk --no-cache add groff && rm -rf /var/cache/apk/*

COPY --from=builder /binaries/bin/* /usr/local/bin/

COPY --from=aws-builder /opt/aws-cli/ /opt/aws-cli/

ENV PATH="/opt/aws-cli/bin:${PATH}"

ENTRYPOINT ["/usr/local/bin/just"]



