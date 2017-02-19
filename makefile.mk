#
# Nim oriented build system
#


# Make sure that any failure in a pipe fails the build
SHELL = /bin/bash -o pipefail

# Add to the bin path to support travis CI builds
export PATH := $(CURDIR)/Nim/bin:$(PATH)


# The path to the NimMakefile
NIMMAKEFILE_DIR ?= $(shell \
	cd $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)));pwd)

# A list of all test files
TESTS ?= $(wildcard test/*_test.nim)

# A list of binaries
BINS ?= $(wildcard bin/*.nim)

# The name of this project
PROJECT ?= $(basename $(firstword $(wildcard *.nimble)))

# Require that a nimble file exists
_ := $(or $(PROJECT),\
	$(error Could not determine Project name. Please create a nimble file or define PROJECT))

# A list of sources
SOURCES ?= $(wildcard $(PROJECT).nim) $(shell find $(PROJECT) -name "*.nim" 2> /dev/null)

# Publicly includable sources
PUBLIC_SOURCES ?= $(foreach src,$(SOURCES),$(if $(findstring /private/,$(src)),,$(src)))

# The compiler to use
COMPILER ?= nimble

# primary compiler flags
CORE_FLAGS ?= --verbosity:0 --hint[Processing]:off --hint[XDeclaredButNotUsed]:off

# The location of the nimcache
NIMCACHE ?= ./build/nimcache


# Create the build directory
$(shell mkdir -p build)


# The location of the binary for pulling dependencies
DEPENDENCIES_BIN = $(CURDIR)/build/dependencies

# Compile the dependency extractor
$(shell test -f $(DEPENDENCIES_BIN) || (which nim > /dev/null && \
	nim c $(CORE_FLAGS) --nimcache:$(NIMCACHE) \
		--out:$(DEPENDENCIES_BIN) $(NIMMAKEFILE_DIR)/dependencies.nim))

# Returns the dependencies for a file
DEPENDENCIES = $(shell test -f $(DEPENDENCIES_BIN) && $(DEPENDENCIES_BIN) $1)


# Compiles a nim file
define COMPILE
@mkdir -p $(dir build/$(or $2,$(basename $1))); \
$(COMPILER) c $(CORE_FLAGS) $(FLAGS) \
	--path:. --nimcache:$(NIMCACHE) \
	--out:$(CURDIR)/build/$(or $2,$(basename $1)) \
	$1
endef


# Run all targets
.PHONY: all
all: sources test bin readme


# Takes a list of source files and returns the target files that represent whether they
# have been compiled
source_targets = $(patsubst %.nim,build/sources/%.bin,$1)

# Public source targets
define SOURCE_RULE
$(call source_targets,$1): $1 $(call source_targets,$(call DEPENDENCIES,$1)) $(wildcard *.nimble)
	@echo
	@echo "$1"
	$(call COMPILE,$1,sources/$(basename $1).bin)
endef

# Define a target for each source file
$(foreach file,$(SOURCES),$(eval $(call SOURCE_RULE,$(file))))

# Compiling all source files
.PHONY: sources
sources: $(call source_targets,$(PUBLIC_SOURCES))


# Test targets
define TEST_RULE
build/$(basename $1): $1 $(call DEPENDENCIES,$1) $(wildcard *.nimble)
	@echo
	@echo "$1"
	$(call COMPILE,$1)

build/test_run/$(basename $1): build/$(basename $1)
	@echo
	build/$(basename $1)
	@mkdir -p $(dir build/test_run/$(basename $1))
	@touch build/test_run/$(basename $1)
endef

# Define a target for each test file
$(foreach test,$(TESTS),$(eval $(call TEST_RULE,$(test))))

# Run all tests
.PHONY: test
test: $(addprefix build/test_run/,$(basename $(TESTS)))


# Binary target
define BIN_RULE
build/$(basename $1): $1 $(call DEPENDENCIES,$1) $(wildcard *.nimble)
	@echo
	@echo "$1"
	$(call COMPILE,$1)
endef

# Define a target for each binary file
$(foreach bin,$(BINS),$(eval $(call BIN_RULE,$(bin))))

# Build all binaries
.PHONY: bin
bin: $(addprefix build/,$(basename $(BINS)))


# A script that pulls code out of the readme. Source above
build/readme/extract_code: $(NIMMAKEFILE_DIR)/extract_readme_code.nim
	$(call COMPILE,$<,readme/extract_code)

# Execute the script to extract the source
build/readme/readme_%.nim: README.md build/readme/extract_code
	@build/readme/extract_code
	@echo

# Compiles the code in the readme to make sure it works
build/readme/readme_%: build/readme/readme_%.nim $(SOURCES) $(wildcard *.nimble)
	@echo "$<"
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
		inotifywait -qre close_write \
			$(SOURCES) $(TESTS) $(BINS) $(wildcard *.nimble) \
			$(shell $(DEPENDENCIES_BIN) $(SOURCES) $(TESTS) $(BINS)) \
			$(wildcard README.md) \
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
	cd Nim && sh ci/build.sh && ./koch nimble
	./Nim/bin/nim -v
	./Nim/bin/nimble -v

