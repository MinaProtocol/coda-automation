FROM debian:buster

RUN apt update && \
      apt install -y curl python3-pip python3 && \
      curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
      chmod +x ./kubectl && \
      mv ./kubectl /usr/local/bin/kubectl

RUN apt update && \
      apt install -y git

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
