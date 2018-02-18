#! /bin/bash
# Tests of edge case and error behaviour.

. utils.sh

# Define all the targets and their dependencies here.
TARGET_1_TARGET=output1.tmp
TARGET_1_DEPENDENCY=source1.tmp

# shunit2 function called before each test.
setUp()
{
    # Run all tests in a tmp dir.
    cd "${SHUNIT_TMPDIR}" || exit

    # Clean any lingering files before a test.
    # There's no need to clean up at the end because the tmp dir is cleaned up
    # by shunit2 itself.
    clean_tmp_files

    # Put some initial source files used by rules in place.
    echo "example source line" >> "${TARGET_1_DEPENDENCY}"
}

# -----
# Tests
# -----

test_err_on_blank_suffix()
{
    # A blank suffix should cause make to bail out with an error.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_SUFFIX= 2>/dev/null
    assertTrue "Blank suffix didn't fail" "(( $? != 0 ))"
}

# Handle a simple case where a hash file gets corrupted (e.g. empty because
# a write failed or similar).
test_empty_hash_file()
{
    # First create a hash file, then empty it.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_made_n_times ${TARGET_1_TARGET} 1
    assertTrue "Hash file not created" \
        "[ -f ${TARGET_1_DEPENDENCY}${DEFAULT_HASH_FILE_SUFFIX} ]"
    echo -n > ${TARGET_1_DEPENDENCY}${DEFAULT_HASH_FILE_SUFFIX}

    # Now touch the file and re-make - the file should be remade, and the hash
    # file replaced.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assertTrue "Make failed with empty hash" "$?"
    assert_file_made_n_times ${TARGET_1_TARGET} 2

    # Now that the hash file is in place, another touch shouldn't cause the
    # target to be re-made a third time.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_made_n_times ${TARGET_1_TARGET} 2
}

. /usr/bin/shunit2
