FROM debian:buster-slim

RUN apt update \
  && apt install -y apt-transport-https gnupg2 curl git python3-pip python3

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
RUN apt update && apt install -y kubectl

ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache

COPY ./services/coda-network-services/ /code

COPY ./scripts /scripts

# Allows docker to cache installed dependencies between builds
COPY services/coda-network-services/requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

WORKDIR /code
RUN chmod -R 777 /code/
RUN chmod -R 777 /scripts/

CMD [ "bash", "main.sh" ]
