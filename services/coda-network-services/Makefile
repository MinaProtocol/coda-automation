filepath        :=      $(PWD)
versionfile     :=      $(filepath)/version.txt
version         :=      $(shell cat $(versionfile))

# Deployment Commands
release: 
	cd ../../ && \
	pwd && \
	docker build -t codaprotocol/coda-network-services:$(version) -f services/coda-network-services/Dockerfile  .
	docker tag codaprotocol/coda-network-services:$(version) gcr.io/o1labs-192920/coda-network-services:latest
	docker push gcr.io/o1labs-192920/coda-network-services:latest

build: 
	cd ../../ && \
	docker build -t codaprotocol/coda-network-services:$(version) -f services/coda-network-services/Dockerfile .
