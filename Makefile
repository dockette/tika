DOCKER_IMAGE=dockette/tika
DOCKER_TAG?=latest
DOCKER_PLATFORMS?=linux/amd64,linux/arm64
VERSION:=$(shell cat VERSION)

TIKA_VERSION?=3.3.1.0
TIKA_PORT?=19998

TIKA_LANGS=ara ces chi_sim chi_tra deu eng fra hin hun ita jpn kor nld osd pol por rus slk spa tur ukr

.PHONY: build
build:
	docker build \
		--build-arg TIKA_VERSION=${TIKA_VERSION} \
		-t ${DOCKER_IMAGE}:${DOCKER_TAG} \
		.

.PHONY: push
push:
	docker buildx build \
		--platform ${DOCKER_PLATFORMS} \
		--build-arg TIKA_VERSION=${TIKA_VERSION} \
		-t ${DOCKER_IMAGE}:${DOCKER_TAG} \
		--push \
		.

.PHONY: run
run:
	docker run --rm -it \
		-p ${TIKA_PORT}:9998 \
		${DOCKER_IMAGE}:${DOCKER_TAG}

.PHONY: shell
shell:
	docker run --rm -it --entrypoint /bin/bash ${DOCKER_IMAGE}:${DOCKER_TAG}

.PHONY: test
test: _testcase-langs _testcase-config

# Smoke test: start the server, OCR a scanned Slovak PDF
.PHONY: test-docker
test-docker:
	IMAGE=${DOCKER_IMAGE}:${DOCKER_TAG} PORT=${TIKA_PORT} ./tests/smoke.sh

.PHONY: _testcase-langs
_testcase-langs:
	@langs="$$(docker run --rm --entrypoint tesseract ${DOCKER_IMAGE}:${DOCKER_TAG} --list-langs 2>/dev/null)"; \
	missing=""; \
	for l in ${TIKA_LANGS}; do echo "$$langs" | grep -qx "$$l" || missing="$$missing $$l"; done; \
	if [ -n "$$missing" ]; then echo "languages missing:$$missing"; exit 1; fi; \
	echo "languages ok: ${TIKA_LANGS}"

.PHONY: _testcase-config
_testcase-config:
	docker run --rm --entrypoint test ${DOCKER_IMAGE}:${DOCKER_TAG} -r /tika-config.xml
	@echo "config ok: /tika-config.xml"

.PHONY: version
version:
	@echo ${VERSION}

.PHONY: release
release:
	@date -u +%Y.%m.%d > VERSION
	@echo "VERSION: ${VERSION} -> $$(cat VERSION)"
	@echo "next: git commit -am \"Release: $$(cat VERSION)\" && git push"
