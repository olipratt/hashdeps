

lint:
	shellcheck tests/*.sh

test: lint
	cd tests && ./test_mainline.sh
