DOCKER ?= docker
ORG = USERNAME
BINARY = istio-1.5-migration
TAG ?= dev

# This build step is not used in CI Pipeline, only for development purposes
.PHONY: build
build:
	$(DOCKER) build -t $(ORG)/$(BINARY):$(TAG) .
