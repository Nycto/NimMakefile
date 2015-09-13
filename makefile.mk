#
# Nim oriented build system
#

# Make sure that any failure in a pipe fails the build
SHELL = /bin/bash -o pipefail

# Add to the bin path to support travis CI builds
export PATH := $(CURDIR)/nimble/src:$(CURDIR)/Nim/bin:$(PATH)

# A list of all test files
TESTS ?= $(wildcard test/*_test.nim)

# A list of binaries
BINS ?= $(wildcard bin/*.nim)

# A list of sources
SOURCES ?= $(wildcard *.nim) \
	$(shell find src private -name "*.nim" 2> /dev/null)


# Create the build directory
$(shell mkdir -p build)

# The location of the binary for pulling dependencies
DEPENDENCIES_BIN = $(CURDIR)/build/dependencies

# Compile the dependency extractor
$(shell test -f $(DEPENDENCIES_BIN) || (which nim > /dev/null && \
	nim c --nimcache:./build/nimcache --verbosity:0 \
		--out:$(DEPENDENCIES_BIN) NimMakefile/dependencies.nim))

# Returns the dependencies for a file
DEPENDENCIES = $(shell test -f $(DEPENDENCIES_BIN) && $(DEPENDENCIES_BIN) $1)


# Compiles a nim file
define COMPILE
@mkdir -p $(dir build/$(or $2,$(basename $1))); \
nimble c $(FLAGS) \
	--path:. --nimcache:./build/nimcache --verbosity:0 \
	--out:$(CURDIR)/build/$(or $2,$(basename $1)) \
	$1
endef


# Run all targets
.PHONY: all
all: test bin readme


# Test targets
define TEST_RULE
build/$(basename $1): $1 $(call dependencies,$1)
	$(call COMPILE,$1)
	$$@
endef

# Define a target for each test file
$(foreach test,$(TESTS),$(eval $(call TEST_RULE,$(test))))

# Run all tests
.PHONY: test
test: $(addprefix build/,$(basename $(TESTS)))


# Binary target
define BIN_RULE
build/$(basename $1): $1 $(call dependencies,$1)
	$(call COMPILE,$1)
endef

# Define a target for each binary file
$(foreach bin,$(BINS),$(eval $(call BIN_RULE,$(bin))))

# Build all binaries
.PHONY: bin
bin: $(addprefix build/,$(basename $(BINS)))


# A script that pulls code out of the readme. Source above
build/readme/extract_code: NimMakefile/extract_readme_code.nim
	$(call COMPILE,$<,readme/extract_code)

# Execute the script to extract the source
build/readme/readme_%.nim: README.md build/readme/extract_code
	@build/readme/extract_code
	@echo

# Compiles the code in the readme to make sure it works
build/readme/readme_%: build/readme/readme_%.nim $(SOURCES)
	@echo "Compiling $<"
	$(call COMPILE,$<,readme/readme_$*)
	@echo
	$@
	@echo

# Define a general rule that compiles all the readme code
readme: $(addprefix build/readme/readme_,$(shell seq 1 \
	$(shell cat README.md 2> /dev/null | grep '```nim' | wc -l)))


# Watches for changes and reruns
.PHONY: watch
watch:
	@while true; do \
		make $(WATCH); \
		inotifywait -qre close_write `find . -name "*.nim"` README.md \
			> /dev/null; \
		echo "Change detected, re-running..."; \
	done

# Executes the compiler with profiling enabled
.PHONY: profile
profile:
	make FLAGS="--profiler:on --stackTrace:on"

# Remove all build artifacts
.PHONY: clean
clean:
	rm -rf build


# Updates to the latest version of
.PHONY: update-nimmakefile
update-nimmakefile:
	cd NimMakefile;
	git fetch origin;
	git merge --ff-only origin/master;


# Sets up the travis.yml file needed to do a build
.PHONY: travis-setup
travis-setup:
	echo "os: linux" > .travis.yml
	echo "language: c" >> .travis.yml
	echo "install: make travis-install" >> .travis.yml
	echo "script: make" >> .travis.yml


# Downloads everything necessary to run a build on a Travis CI box
.PHONY: travis-install
travis-install:
	git clone -b devel --depth 1 git://github.com/Araq/Nim.git
	cd Nim && sh bootstrap.sh
	git clone https://github.com/nim-lang/nimble.git
	./Nim/bin/nim c --verbosity:0 ./nimble/src/nimble
	./nimble/src/nimble install --accept

