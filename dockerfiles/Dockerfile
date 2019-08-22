# Last updated: 2019-09-20
# Utility image with deploy tools
FROM debian:stable

## TERRAFORM
## derived from https://learn.hashicorp.com/terraform/getting-started/install.html
ARG TERRAFORM_VERSION=0.12.6
ARG TERRAFORM_URL=https://releases.hashicorp.com/terraform
ARG TERRAFORM_SHA256=6544eb55b3e916affeea0a46fe785329c36de1ba1bdb51ca5239d3567101876f
# eg https://releases.hashicorp.com/terraform/0.12.6/terraform_0.12.6_linux_amd64.zip

RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends ca-certificates wget unzip \
    && mkdir /terraform \
    && cd /terraform \
    && wget -q -O terraform.zip ${TERRAFORM_URL}/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && echo "$TERRAFORM_SHA256 terraform.zip" | sha256sum -c \
    && unzip terraform.zip -d /bin/ \
    && rm terraform.zip \
    && cd .. \
    && rmdir terraform

## ANSIBLE
## derived from https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#latest-releases-via-apt-debian
ARG ANSIBLE_VERSION=2.8.4-1ppa~trusty

RUN apt-get -qq update \
    && apt-get -qq install -y gnupg2 \
    && echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" > /etc/apt/sources.list.d/ansible.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 \
    && apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends ansible=${ANSIBLE_VERSION}

## COMMON TOOLS and python3 support
RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends git openssh-client python3 python3-dnspython python3-setuptools python3-pip rsync sudo
RUN pip3 install ansible awscli boto boto3 requests
