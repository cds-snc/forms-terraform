FROM mcr.microsoft.com/vscode/devcontainers/base:buster@sha256:aa7bf154dac15515fafbbe1841e1f24d509692ee5612b928363334d46390aaa2

ARG USERNAME=vscode
ARG AWS_SAM_VERSION
ARG AWS_SAM_CHECKSUM

# Install packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends build-essential ca-certificates curl dnsutils git gnupg2 jq libffi-dev make openssh-client python3-dev python3-pip vim zsh \
    && apt-get autoremove -y && apt-get clean -y 

# Install aws-sam
ARG AWS_SAM_SRC=https://github.com/aws/aws-sam-cli/releases/download
RUN curl -Lo aws-sam-cli.zip "${AWS_SAM_SRC}/v${AWS_SAM_VERSION}/aws-sam-cli-linux-x86_64.zip" \
    && echo "${AWS_SAM_CHECKSUM} aws-sam-cli.zip" | sha256sum --check \
    && unzip aws-sam-cli.zip -d sam-installation \
    && ./sam-installation/install \
    && rm -r aws-sam* \
    && rm -r sam-installation*

# Setup AWS Credentials
RUN mkdir -p /home/vscode/.aws

RUN echo "\n\
[default]\n\
aws_access_key_id=foo\n\
aws_secret_access_key=bar\n\
" >> /home/vscode/.aws/credentials

RUN echo "\n\
[default]\n\
region=ca-central-1\n\
output=json\n\
" >> /home/vscode/.aws/config

ENV SHELL /bin/zsh

# Setup aliases and autocomplete
RUN echo "\n\
complete -C /usr/bin/aws_completer aws\n\
complete -C /usr/local/bin/terraform terraform\n\
complete -C /usr/local/bin/terraform terragrunt\n\
alias tf='terraform'\n\
alias tg='terragrunt'\n\
alias ll='la -la' \n\
alias laws='aws --endpoint-url=http://localstack:4566 --region=ca-central-1'" >> /home/vscode/.zshrc