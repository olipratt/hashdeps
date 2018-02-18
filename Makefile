

lint:
	cd tests && shellcheck -x *.sh

mainline_tests:
	cd tests && ./test_mainline.sh

deps_combinations_tests:
	cd tests && ./test_deps_combinations.sh

test: lint mainline_tests deps_combinations_tests
