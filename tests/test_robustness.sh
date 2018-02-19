#! /bin/bash
# Tests of edge case and error behaviour.

. ./utils.sh

# shunit2 function called before each test.
setUp()
{
    # Run all tests in a tmp dir. This way there's no need to clean up at the
    # end because the tmp dir is cleaned up by shunit2 itself.
    cd "${SHUNIT_TMPDIR}" || exit

    # Clean any lingering files before a test.
    clean_tmp_files

    # Put some initial source files used by rules in place.
    echo "example source line" >> "${TARGET_1_DEPENDENCY}"
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

# Handle a simple case where a hash file gets corrupted (e.g. empty because
# a write failed or similar).
test_empty_hash_file()
{
    # First create a hash file, then empty it.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
    assertTrue "Hash file not created" \
        "[ -f ${TARGET_1_DEPENDENCY}${DEFAULT_HASH_FILE_SUFFIX} ]"
    echo -n > ${TARGET_1_DEPENDENCY}${DEFAULT_HASH_FILE_SUFFIX}
    # Also move back the modification time so that it's not newer than the
    # target which would force it to be remade.
    touch --reference=${TARGET_1_TARGET} \
        ${TARGET_1_DEPENDENCY}${DEFAULT_HASH_FILE_SUFFIX}

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
test_whitespace_in_hash_file()
{
    # First create a hash file, then empty it.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
    assertTrue "Hash file not created" \
        "[ -f ${TARGET_1_DEPENDENCY}${DEFAULT_HASH_FILE_SUFFIX} ]"
    echo " " >> ${TARGET_1_DEPENDENCY}${DEFAULT_HASH_FILE_SUFFIX}
    # Also move back the modification time so that it's not newer than the
    # target which would force it to be remade.
    touch --reference=${TARGET_1_TARGET} \
        ${TARGET_1_DEPENDENCY}${DEFAULT_HASH_FILE_SUFFIX}

    # Now touch the file and re-make - the hash should stil be valid and so the
    # target should not be remade.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assertTrue "Make failed with extra whitespace in hash" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
}

# If for whatever reason the target file is significantly older than the
# dependency and hash files but the hash of the dependency hasn't changed, then
# the target still shouldn't be remade.
# This is optional behaviour controlled by HASHDEPS_HASH_FILE_TIMESTAMP.
test_old_target_modification_time()
{
    # First create a hash file, then empty it.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_FILE_TIMESTAMP='"5 years ago"'
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1

    # Now change the target to be significantly older than the dependencies.
    touch -d "2 hours ago" ${TARGET_1_TARGET}

    # The target should still not be re-made.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_FILE_TIMESTAMP='"5 years ago"'
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1

    # Modifying the dependency file will still re-make the target though.
    edit_file_to_force_remake ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_FILE_TIMESTAMP='"5 years ago"'
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 2
}

. /usr/bin/shunit2
