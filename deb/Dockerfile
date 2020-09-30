FROM debian:stretch


RUN apt-get update
RUN apt-get install -y apt-transport-https ca-certificates
RUN echo "deb [trusted=yes] http://packages.o1test.net unstable main" | tee /etc/apt/sources.list.d/coda.list
RUN apt-get update

RUN apt-get install -y coda-testnet-postake-medium-curves=0.0.16-beta7+-feature-mainnet-parameter-test-210996f-PV84ecd12e

RUN apt-get install -y curl

ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache

COPY ./daemon.json /config/daemon.json

CMD [ "/bin/bash", "" ]
