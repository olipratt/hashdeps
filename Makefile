
# Linting should be run before any tests to make sure that the tests will
# actually run safely.
lint:
	cd tests && shellcheck -x *.sh

mainline_tests: lint
	cd tests && ./test_mainline.sh

deps_combinations_tests: lint
	cd tests && ./test_deps_combinations.sh

robustness_tests: lint
	cd tests && ./test_robustness.sh

test: lint mainline_tests deps_combinations_tests robustness_tests
