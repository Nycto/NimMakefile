#
# Nim oriented build system
#

# Make sure that any failure in a pipe fails the build
SHELL = /bin/bash -o pipefail

# Add to the bin path to support travis CI builds
export PATH := $(CURDIR)/nimble/src:$(CURDIR)/Nim/bin:$(PATH)

# A list of source files
SOURCES ?= $(wildcard *.nim) $(wildcard private/*.nim)


# Compiles a nim file
define COMPILE
@mkdir -p $(dir build/$(or $2,$(basename $1)));
nimble c $(FLAGS) \
		--path:. --nimcache:./build/nimcache --verbosity:0 \
		--out:$(CURDIR)/build/$(or $2,$(basename $1)) \
		$1
endef


# Run all targets
.PHONY: all
all: test bin readme


# Test targets
build/test/%_test: test/%_test.nim $(SOURCES)
	$(call COMPILE,$<)
	$@

# Run all tests
.PHONY: test
test: $(addprefix build/,$(basename $(wildcard test/*_test.nim)))


# Compile anything in the bin folder
build/bin/%: bin/%.nim $(SOURCES) $(wildcard bin/private/*.nim)
	$(call COMPILE,$<)

# Build all binaries
.PHONY: bin
bin: $(addprefix build/,$(basename $(wildcard bin/*.nim)))


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
	$(shell grep '```nim' README.md | wc -l)))


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


# Sets up a travis build
.PHONY: travis-install
travis-install:
	git clone -b devel --depth 1 git://github.com/Araq/Nim.git
	cd Nim && sh bootstrap.sh
	git clone https://github.com/nim-lang/nimble.git
	./Nim/bin/nim c --verbosity:0 ./nimble/src/nimble
	./nimble/src/nimble install --accept

