FROM python:3.7-stretch

ARG GCLOUDSDK_DOWNLOAD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-296.0.1-linux-x86_64.tar.gz"

RUN apt update && apt install -y gnupg2 lsb-core apt-transport-https curl jq wget graphviz

# Install GCloud SDK
RUN wget ${GCLOUDSDK_DOWNLOAD_URL} && tar -zxf $(basename ${GCLOUDSDK_DOWNLOAD_URL}) -C /usr/local/
RUN ln --symbolic --force /usr/local/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud

# Install K8s/network utilities
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" \
    | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN apt update && apt install -y kubectl

ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache

COPY . /code

COPY ./scripts /scripts
COPY ./entrypoints /entrypoint.d

COPY ./requirements.txt requirements.txt
RUN pip install -r requirements.txt

WORKDIR /code
RUN chmod -R 777 /code/
RUN chmod -R 777 /scripts/

COPY entrypoint.sh /entrypoint
RUN chmod 777 /entrypoint
ENTRYPOINT ["/entrypoint"]

CMD [ "bash", "main.sh" ]
