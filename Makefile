DOCKER ?= docker

ORG = rancher
BINARY = istio-1.5-migration
TAG ?= dev

.PHONY: image-build
image-build:
	$(DOCKER) build -t $(ORG)/$(BINARY):$(TAG) .

.PHONY: image-push
image-push:
	$(DOCKER) push $(ORG)/$(BINARY):$(TAG)
