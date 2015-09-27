assert:
	make -p all | grep -P ^build/bin/example_bin: | grep bin/example_bin.nim
	make -p all | grep -P ^build/bin/example_bin: | grep testing.nim
	make -p all | grep -P ^build/bin/example_bin: | grep src/one.nim
	make -p all | grep -P ^build/bin/example_bin: | grep src/two.nim
	make -p all | grep -P ^build/bin/example_bin: | grep src/three.nim
	make -p all | grep -P ^build/test/example_test: | grep test/example_test.nim
	make -p all | grep -P ^build/test/example_test: | grep testing.nim
	make -p all | grep -P ^build/test/example_test: | grep src/one.nim
	make -p all | grep -P ^build/test/example_test: | grep src/two.nim
	make -p all | grep -P ^build/test/example_test: | grep src/three.nim

include ../../makefile.mk
