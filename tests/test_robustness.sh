#! /bin/bash
# Tests of edge case and error behaviour.

. ./utils.sh

# shunit2 function called before each test.
setUp()
{
    prepare_and_cd_to_test_temp_dir

    # Put some initial source files used by rules in place.
    echo "example source line" > "${TARGET_1_DEPENDENCY}"
}

# -----
# Tests
# -----

# A blank suffix should be rejected and cause make to bail out with an error.
test_err_on_blank_suffix()
{
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_SUFFIX= 2>/dev/null
    assertTrue "Blank suffix didn't fail" "(( $? != 0 ))"
}

# A blank timestamp should be rejected when forcing hash generation and cause
# make to bail out with an error.
test_err_on_blank_timestamp_when_forcing()
{
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_FORCE_HASH=y \
        HASHDEPS_HASH_FILE_TIMESTAMP= 2>/dev/null
    assertTrue "Blank timestamp when forcing didn't fail" "(( $? != 0 ))"
}

# Handle a simple case where a hash file gets corrupted (e.g. empty because
# a write failed or similar).
test_empty_hash_file()
{
    # First create a hash file, then empty it.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
    assertTrue "Hash file not created" "[ -f ${TARGET_1_HASH_FILE} ]"
    echo -n > ${TARGET_1_HASH_FILE}
    # Also move back the modification time so that it's not newer than the
    # target which would force it to be remade.
    touch --reference=${TARGET_1_TARGET} ${TARGET_1_HASH_FILE}

    # Now touch the file and re-make - the file should be remade, and the hash
    # file replaced.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assertTrue "Make failed with empty hash" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 2

    # Now that the hash file is in place, another touch shouldn't cause the
    # target to be re-made a third time.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 2
}

# It shouldn't be possible, but we should cope gracefully with any trailing
# whitespace ending up in the hash file.
test_trailing_whitespace_in_hash_file()
{
    # First create a hash file, then append whitespace to it.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
    assertTrue "Hash file not created" "[ -f ${TARGET_1_HASH_FILE} ]"
    echo " " >> ${TARGET_1_HASH_FILE}
    # Also move back the modification time so that it's not newer than the
    # target which would force it to be remade.
    touch --reference=${TARGET_1_TARGET} ${TARGET_1_HASH_FILE}

    # Now touch the file and re-make - the hash should still be valid and so
    # the target should not be remade.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assertTrue "Make failed with extra whitespace in hash" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
}

. /usr/bin/shunit2
