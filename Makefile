RUN         ?= -V
ROOTFS       = world/rootfs.tar.gz
ROOTFS_SIZE  = $(shell du -skh $(ROOTFS) | awk '{print $1}')
PV_CMD       = pv -W -e -b -s $(ROOTFS_SIZE) -i 0.25 -N "Creating docker image"

all: build package build-images test

build: FORCE
	@docker build -t asaaki/rust-build .

package:
	@docker run --rm -ti -v `pwd`/world:/world asaaki/rust-build

IMAGES = \
	build-mrustc \
	build-mrustc-rustc \
	build-mrustc-mrustc \
	build-mrustc-cargo \
	build-mrustc-mcargo-build

build-images: $(IMAGES)

build-mrustc: FORCE
	@cat $(ROOTFS) | $(PV_CMD) | \
		docker import \
		--change 'WORKDIR /app' \
		--change 'ENTRYPOINT ["/usr/bin/rustc"]' \
		--change 'CMD ["-V"]' \
		- asaaki/mrustc:master
	@docker tag -f asaaki/mrustc:master asaaki/mrustc:latest

build-mrustc-rustc: FORCE build-mrustc
	@docker build -f Dockerfile.mrustc-rustc -t asaaki/mrustc-rustc .

build-mrustc-mrustc: FORCE build-mrustc
	@docker build -f Dockerfile.mrustc-mrustc -t asaaki/mrustc-mrustc .

build-mrustc-cargo: FORCE build-mrustc
	@docker build -f Dockerfile.mrustc-cargo -t asaaki/mrustc-cargo .

build-mrustc-mcargo-build: FORCE build-mrustc
	@docker build -f Dockerfile.mrustc-mcargo-build -t asaaki/mrustc-mcargo-build .

run-rustc:
	@docker run --rm -v `pwd`/app:/app asaaki/mrustc-rustc $(RUN)
run-cargo:
	@docker run --rm -v `pwd`/app:/app asaaki/mrustc-cargo $(RUN)

test: FORCE
	@cd app && \
		docker run --rm -ti -v `pwd`:/app asaaki/mrustc-mrustc hello.rs && \
		docker build -t local/rhello . && \
		docker run --rm local/rhello

FORCE:
