#
# Tests this makefile
#

.PHONY: test
test:
	@for test in $(wildcard test/*); do (cd $$test; make); done

.PHONY: clean
clean:
	@for test in $(wildcard test/*); do (cd $$test; make clean); done

