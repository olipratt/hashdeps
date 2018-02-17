#! /bin/bash

# For the tests, disable makefiles from printing their working directory as it
# produces too much stdout spam.
export MAKEFLAGS+=--no-print-directory

# Use a log function rather than echo so we have better output control.
log()
{
    echo "$@"
}

# All tests should only create files with the suffixes covered here so that
# they are always cleaned up.
clean_tmp_files()
{
    log "Cleaning tmp files..."
    rm -fv -- *.tmp
    rm -fv -- *.dephash
    rm -frv -- hashes
}

# shunit2 function called before each test.
setUp()
{
    # Clean any lingering files before a test.
    clean_tmp_files
}

# shunit2 function called after each test.
tearDown()
{
    # Any files left around by a test should be removed before the next one.
    clean_tmp_files
}

# -----
# Tests
# -----

test_touch_means_no_remake()
{
    # Make the file, which will create it with one line.
    touch file1.tmp
    make -f mainline.mk file2.tmp
    assertEquals "First make failed" 1 "$(wc -l < file2.tmp)"

    # Touch the dependency and re-make the file - it should be unchanged.
    touch file1.tmp
    make -f mainline.mk file2.tmp
    assertEquals "Second make failed" 1 "$(wc -l < file2.tmp)"
}

test_edit_means_remake()
{
    # Make the file, which will create it with one line.
    touch file1.tmp
    make -f mainline.mk file2.tmp
    assertEquals "First make failed" 1 "$(wc -l < file2.tmp)"

    # Edit the dependency and re-make the file - it should be updated.
    echo "text" >> file1.tmp
    make -f mainline.mk file2.tmp
    assertEquals "Second make failed" 2 "$(wc -l < file2.tmp)"
}

test_touch_means_no_remake_hash_dir()
{
    # Make the file, which will create it with one line.
    touch file1.tmp
    make -f mainline.mk file2.tmp HASHDEPS_HASH_TREE_DIR=./hashes
    assertTrue "Didn't create hash directory" "[ -d hashes ]"
    assertEquals "First make failed" 1 "$(wc -l < file2.tmp)"

    # Touch the dependency and re-make the file - it should be unchanged.
    touch file1.tmp
    make -f mainline.mk file2.tmp HASHDEPS_HASH_TREE_DIR=./hashes
    assertEquals "Second make failed" 1 "$(wc -l < file2.tmp)"
}

test_edit_means_remake_hash_dir()
{
    # Make the file, which will create it with one line.
    touch file1.tmp
    make -f mainline.mk file2.tmp HASHDEPS_HASH_TREE_DIR=./hashes
    assertTrue "Didn't create hash directory" "[ -d hashes ]"
    assertEquals "First make failed" 1 "$(wc -l < file2.tmp)"

    # Edit the dependency and re-make the file - it should be updated.
    echo "text" >> file1.tmp
    make -f mainline.mk file2.tmp HASHDEPS_HASH_TREE_DIR=./hashes
    assertEquals "Second make failed" 2 "$(wc -l < file2.tmp)"
}

test_touch_means_no_remake_two_deps()
{
    # Make the file, which will create it with one line.
    touch file10.tmp file11.tmp
    make -f mainline.mk file12.tmp
    assertEquals "First make failed" 1 "$(wc -l < file12.tmp)"

    # Touch the dependencies and re-make the file - it should be unchanged.
    touch file10.tmp file11.tmp
    make -f mainline.mk file12.tmp
    assertEquals "Second make failed" 1 "$(wc -l < file12.tmp)"
}

test_edit_means_remake_two_deps()
{
    # Make the file, which will create it with one line.
    touch file10.tmp file11.tmp
    make -f mainline.mk file12.tmp
    assertEquals "First make failed" 1 "$(wc -l < file12.tmp)"

    # Edit a dependency and re-make the file - it should be updated.
    echo "text" >> file11.tmp
    make -f mainline.mk file12.tmp
    assertEquals "First make failed" 2 "$(wc -l < file12.tmp)"
}

. shunit2
