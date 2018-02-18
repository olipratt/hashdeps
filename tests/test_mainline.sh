#! /bin/bash
# Tests of basic, mainline behaviour.

. utils.sh

# Define all the targets and their dependencies here.
TARGET_1_TARGET=output1.tmp
TARGET_1_DEPENDENCY=source1.tmp

# shunit2 function called before each test.
setUp()
{
    # Run all tests in a tmp dir.
    cd "${SHUNIT_TMPDIR}"

    # Clean any lingering files before a test.
    # There's no need to clean up at the end because the tmp dir is cleaned up
    # by shunit2 itself.
    clean_tmp_files

    # Put some initial source files used by rules in place.
    echo "example source line" >> "${TARGET_1_DEPENDENCY}"
}

# When a file is made, it gains a line of content, so use that to check how
# many times a file has been made.
assert_file_made_n_times()
{
    local filename=$1
    local n=$2
    local times_made
    times_made=$(wc -l < "${filename}")
    assertEquals "made ${times_made} times instead" "${n}" "${times_made}"
}

# -----
# Tests
# -----

test_touch_means_no_remake()
{
    # Make the target so that it exists.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_made_n_times ${TARGET_1_TARGET} 1

    # Touch the dependency and re-make the file - it should be unchanged.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_made_n_times ${TARGET_1_TARGET} 1
}

test_edit_means_remake()
{
    # Make the target so that it exists.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_made_n_times ${TARGET_1_TARGET} 1

    # Edit the source file and the target should change.
    edit_file_to_force_remake ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_made_n_times ${TARGET_1_TARGET} 2
}

test_touch_means_no_remake_hash_dir()
{
    # Make the target so that it exists.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assert_file_made_n_times ${TARGET_1_TARGET} 1
    assertTrue "Didn't create hash directory" "[ -d ${HASH_DIR_NAME} ]"

    # Touch the dependency and re-make the file - it should be unchanged.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assert_file_made_n_times ${TARGET_1_TARGET} 1
}

test_edit_means_remake_hash_dir()
{
    # Make the target so that it exists.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assert_file_made_n_times ${TARGET_1_TARGET} 1
    assertTrue "Didn't create hash directory" "[ -d ${HASH_DIR_NAME} ]"

    # Edit the source file and the target should change.
    edit_file_to_force_remake ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assert_file_made_n_times ${TARGET_1_TARGET} 2
}

test_clean()
{
    # Make the target, which will create dependency hashes.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_made_n_times ${TARGET_1_TARGET} 1
    assertTrue "Didn't create hash files" "any_hash_files_in_dir ."

    # Cleaning should delete dependency hashes.
    ${MAKE_CMD} hashdeps_clean
    assertFalse "Didn't delete hash files" "any_hash_files_in_dir ."
}

test_clean_hash_dir()
{
    # Make the target, which will create dependency hashes in the tree dir.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assert_file_made_n_times ${TARGET_1_TARGET} 1
    assertTrue "Didn't create hash files" "any_hash_files_in_dir ${HASH_DIR_NAME}"

    # Cleaning should delete dependency hashes.
    ${MAKE_CMD} hashdeps_clean HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assertFalse "Didn't delete hash files" "any_hash_files_in_dir ${HASH_DIR_NAME}"
}

test_disabling()
{
    # Make the target, which should not create dependency hashes.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_DISABLE=y
    assert_file_made_n_times ${TARGET_1_TARGET} 1
    assertFalse "Still created hash files" "any_hash_files_in_dir ."

    # Touch the dependency and re-make the file - it should be updated.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_DISABLE=y
    assert_file_made_n_times ${TARGET_1_TARGET} 2
    assertFalse "Still created hash files" "any_hash_files_in_dir ."
}

test_err_on_blank_suffix()
{
    # A blank suffix should cause make to bail out with an error.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_SUFFIX= 2>/dev/null
    assertTrue "Blank suffix didn't fail" "(( $? != 0 ))"
}

# Cope with Shellcheck not being able to find the shunit file.
# shellcheck disable=SC1091
. shunit2
