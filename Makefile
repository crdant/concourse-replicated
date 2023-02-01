PROJECT_DIR    := $(shell pwd)
CHANNEL        := $(shell git branch --show-current)
APPLICATION    := big-bang

MANIFEST_DIR := $(PROJECT_DIR)/manifests
MANIFESTS    := $(shell find $(MANIFEST_DIR) -name '*.yaml' -o -name '*.tgz')

BUMP           := release
CURRENT_VER    := $(shell semver get $(BUMP))
RELEASE_NOTES  := $(shell git log -1 --pretty="- %B" $(CURRENT_VER)..)

fluxcd: 
	@kustomize build https://repo1.dso.mil/platform-one/big-bang/bigbang.git//base/flux?ref=1.47.0 > $(MANIFEST_DIR)/gotk_components.yaml

channel:
	@replicated channel create --name $(CHANNEL)

lint: $(MANIFESTS)
	@replicated release lint --yaml-dir $(MANIFEST_DIR)

.PHONY: bump
bump:
	@semver up $(BUMP)

release: $(MANIFESTS) bump
	@replicated release create \
		--app $(APPLICATION) \
		--token ${REPLICATED_API_TOKEN} \
		--auto -y \
		--yaml-dir $(MANIFEST_DIR) \
		--version $(shell semver get release) \
		--release-notes "$(RELEASE_NOTES)" \
		--promote $(CHANNEL)
	@git tag $(shell semver get release) -m "release $(shell semver get release) to channel $(CHANNEL): $(RELEASE_NOTES)"

install:
	@kubectl kots install ${REPLICATED_APP}
