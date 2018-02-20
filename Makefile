
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

mod_time_tests: lint
	cd tests && ./test_mod_time_combinations.sh

c_auto_dep_gen_tests: lint
	cd tests && ./test_c_auto_dep_gen.sh

test: lint mainline_tests deps_combinations_tests robustness_tests \
	mod_time_tests c_auto_dep_gen_tests
