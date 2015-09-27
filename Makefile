#
# Tests this makefile
#

.PHONY: test
test: $(wildcard test/*)
	@true


# Defines a rule for building a test
define DEFINE_TEST
.PHONY: $1
$1:
	cd $1 && make
endef

# Define build rules for each test directory
$(foreach test,$(wildcard test/*),$(eval $(call DEFINE_TEST,$(strip $(test)))))


.PHONY: clean
clean:
	@for test in $(wildcard test/*); do (cd $$test; make clean); done

