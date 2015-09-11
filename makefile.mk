#
# Nim oriented build system
#

# Make sure that any failure in a pipe fails the build
SHELL = /bin/bash -o pipefail


# A list of all test names
TESTS ?= $(notdir $(basename $(wildcard test/*_test.nim)))


# Run all targets
.PHONY: all
all: test bin readme

# Run all tests
.PHONY: test
test: $(TESTS)

# Build all binaries
.PHONY: bin
bin: $(addprefix build/,$(notdir $(basename $(wildcard bin/*.nim))))


# Add to the bin path to support travis CI builds
export PATH := $(CURDIR)/nimble/src:$(CURDIR)/Nim/bin:$(PATH)


# Compiles a nim file
define COMPILE
nimble c $(FLAGS) \
		--path:. --nimcache:./build/nimcache --verbosity:0 \
		--out:$(CURDIR)/build/$(notdir $(basename $1)) \
		$1
endef


# Compile anything in the bin folder
build/%: bin/%.nim
	$(call COMPILE,$<)


# A template for defining targets for a test
define DEFINE_TEST

build/$1: test/$1.nim $(shell find -name $(patsubst %_test,%,$1).nim)
	$(call COMPILE,test/$1.nim)

.PHONY: $1
$1: build/$1
	build/$1

endef

# Define a target for each test
$(foreach test,$(TESTS),$(eval $(call DEFINE_TEST,$(test))))


# A script that pulls code out of the readme. Source above
build/extract_readme_code: NimMakefile/extract_readme_code.nim
	@mkdir -p build
	$(call COMPILE,NimMakefile/extract_readme_code.nim)

# Execute the script to extract the source
build/readme_%.nim: README.md build/extract_readme_code
	@build/extract_readme_code
	@echo

# Compiles the code in the readme to make sure it works
build/readme_%: build/readme_%.nim
	@echo "Compiling $<"
	$(call COMPILE,$<)
	@echo
	$@
	@echo

# Define a general rule that compiles all the readme code
readme: $(addprefix build/readme_,$(shell seq 1 \
	$(shell grep '```nim' README.md | wc -l)))


# Watches for changes and reruns
.PHONY: watch
watch:
	$(eval MAKEFLAGS += " -s ")
	@while true; do \
		make TESTS="$(TESTS)"; \
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
	git pull origin master;


# Sets up a travis build
.PHONY: travis-install
travis-install:
	git clone -b devel --depth 1 git://github.com/Araq/Nim.git
	cd Nim && sh bootstrap.sh
	git clone https://github.com/nim-lang/nimble.git
	./Nim/bin/nim c --verbosity:0 ./nimble/src/nimble
	./nimble/src/nimble install --accept

