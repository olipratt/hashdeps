#! /bin/bash
# Tests of basic, mainline behaviour.

. ./utils.sh

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

test_touch_means_no_remake()
{
    # Make the target so that it exists.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1

    # Touch the dependency and re-make the file - it should be unchanged.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
}

test_edit_means_remake()
{
    # Make the target so that it exists.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1

    # Edit the source file and the target should change.
    edit_file_to_force_remake ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 2
}

test_touch_means_no_remake_hash_dir()
{
    # Make the target so that it exists.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
    assertTrue "Didn't create hash directory" "[ -d ${HASH_DIR_NAME} ]"

    # Touch the dependency and re-make the file - it should be unchanged.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
}

test_edit_means_remake_hash_dir()
{
    # Make the target so that it exists.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
    assertTrue "Didn't create hash directory" "[ -d ${HASH_DIR_NAME} ]"

    # Edit the source file and the target should change.
    edit_file_to_force_remake ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 2
}

test_clean()
{
    # Make the target, which will create dependency hashes.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
    assertTrue "Didn't create hash files" "any_hash_files_in_dir ."

    # Cleaning should delete dependency hashes.
    ${MAKE_CMD} hashdeps_clean
    assertFalse "Didn't delete hash files" "any_hash_files_in_dir ."
}

test_clean_hash_dir()
{
    # Make the target, which will create dependency hashes in the tree dir.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
    assertTrue "Didn't create hash files" "any_hash_files_in_dir ${HASH_DIR_NAME}"

    # Cleaning should delete dependency hashes.
    ${MAKE_CMD} hashdeps_clean HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assertFalse "Didn't delete hash files" "any_hash_files_in_dir ${HASH_DIR_NAME}"
}

test_disabling()
{
    # Make the target, which should not create dependency hashes.
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_DISABLE=y
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
    assertFalse "Still created hash files" "any_hash_files_in_dir ."

    # Touch the dependency and re-make the file - it should be updated.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_DISABLE=y
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 2
    assertFalse "Still created hash files" "any_hash_files_in_dir ."
}

# Just check everything works as expected with a different hashing command, but
# don't go as far as checking it's actually being used to create the hash as it
# isn't worth the effort and will make the test fragile.
test_touch_means_no_remake_sha1sum()
{
    # Make the target to create the default hash.
    ${MAKE_CMD} ${TARGET_1_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1

    # Touch and make with a new hash command, which should force a build.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_CMD=sha1sum
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 2

    # Touch and make with the same hash command - there should be no rebuild.
    touch ${TARGET_1_DEPENDENCY}
    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_HASH_CMD=sha1sum
    assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 2
}

. /usr/bin/shunit2
