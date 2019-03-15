SHELL = bash

# git information
GIT_COMMIT := $(shell git rev-parse --short HEAD)
LATEST_TAG := $(shell git describe --tags --abbrev=7 --always)
STABLE_TAG := $(shell git describe --tags --abbrev=0 --always)

UNCOMMITTED := 0
ifneq ($(shell git status --porcelain | wc -c), 0)
UNCOMMITTED := 1
endif

GIT_BRANCH := $(or $(shell git rev-parse --abbrev-ref HEAD))
ifeq ($(GIT_BRANCH),$(LATEST_TAG))
GIT_BRANCH := master
endif

# date/time
built_at := $(shell date +%FT%T%z)
built_by := developers@opwire.org

# go information
GO_VERSION := $(shell go version)

# LDFLAGS
GO_LDFLAGS := $(shell echo "-X main.gitCommit=${GIT_COMMIT} -X main.gitTag=${LATEST_TAG} -X main.builtAt='${built_at}' -X main.builtBy=${built_by}")

build-dev:
	go build -ldflags "${GO_LDFLAGS}"

build-lab:
ifeq ($(UNCOMMITTED),0)
	go build -ldflags "${GO_LDFLAGS}"
else
	@echo "Please commit all of changes before build a LAB edition"
endif

ifeq ($(shell [[ $(UNCOMMITTED) -eq 0 && $(LATEST_TAG) = $(STABLE_TAG) ]] && echo 2),2)
build-all: build-clean build-mkdir
	for GOOS in darwin linux windows; do \
		for GOARCH in 386 amd64; do \
			ARTIFACT_NAME=opwire-agent-${LATEST_TAG}-$$GOOS-$$GOARCH; \
			[[ "$$GOOS" = "windows" ]] && BIN_EXT=".exe" || BIN_EXT=""; \
			env GOOS=$$GOOS GOARCH=$$GOARCH go build -o ./build/$$ARTIFACT_NAME/opwire-agent$$BIN_EXT -ldflags "${GO_LDFLAGS}"; \
			zip -rjm ./build/$$ARTIFACT_NAME.zip ./build/$$ARTIFACT_NAME/ ; \
			rmdir ./build/$$ARTIFACT_NAME/; \
		done; \
	done
else
build-all:
	@echo "Please commit all of changes and make a tag before build releases"
endif

build-clean:
	rm -rf ./build/

build-mkdir:
	mkdir -p ./build/

clean: build-clean
	go clean ./...
	find . -name \*~ | xargs -r rm -f
	rm -f ./opwire-agent
	rm -f ./opwire-lab

info:
	@echo "GO version: $(GO_VERSION)"
	@echo "Current git branch: $(GIT_BRANCH)"
	@echo "  The stable git Tag: $(STABLE_TAG)"
	@echo "  The latest git Tag: $(LATEST_TAG)"
	@echo "Current git commit: $(GIT_COMMIT)"
ifeq ($(UNCOMMITTED),0)
	@echo "Current change has committed"
else
	@echo "Current change is uncommitted"
endif
