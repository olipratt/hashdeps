#! /bin/bash
# Test integration with GCC's automatic dependency generation.
# For more info see:
# https://www.gnu.org/software/make/manual/html_node/Automatic-Prerequisites.html

. ./utils.sh

# shunit2 function called before each test.
setUp()
{
    prepare_and_cd_to_test_temp_dir
}

# -----
# Tests
# -----

test_basic_c_dependency_generation()
{
    # Put the source files in place for the test.
    ${MAKE_CMD} output4.tmp_sources

    # Just make the target and confirm everything works.
    ${MAKE_CMD} ${TARGET_4_TARGET}
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 1

    # Now touch the .c, .h, and .d files and confirm nothing gets rebuilt.
    touch ${TARGET_4_C_FILE}
    ${MAKE_CMD} ${TARGET_4_TARGET}
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 1

    touch ${TARGET_4_H_FILE}
    ${MAKE_CMD} ${TARGET_4_TARGET}
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 1

    touch ${TARGET_4_D_FILE}
    ${MAKE_CMD} ${TARGET_4_TARGET}
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 1
}

# Same as above but store the hashes in a separate directory tree.
test_basic_c_dependency_generation_hash_dir()
{
    # Put the source files in place for the test.
    ${MAKE_CMD} output4.tmp_sources

    # Just make the target and confirm everything works.
    ${MAKE_CMD} ${TARGET_4_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 1

    # Now touch the .c, .h, and .d files and confirm nothing gets rebuilt.
    touch ${TARGET_4_C_FILE}
    ${MAKE_CMD} ${TARGET_4_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 1

    touch ${TARGET_4_H_FILE}
    ${MAKE_CMD} ${TARGET_4_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 1

    touch ${TARGET_4_D_FILE}
    ${MAKE_CMD} ${TARGET_4_TARGET} HASHDEPS_HASH_TREE_DIR="${HASH_DIR_NAME}"
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 1
}

# Same again, but this time without hashdeps doing anything every touch should
# force a rebuild.
test_basic_c_dependency_generation_hashdeps_disabled()
{
    # Put the source files in place for the test.
    ${MAKE_CMD} output4.tmp_sources

    # Just make the target and confirm everything works.
    ${MAKE_CMD} ${TARGET_4_TARGET} HASHDEPS_DISABLE=y
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 1

    # Now touch the .c, .h, and .d files and confirm everything gets rebuilt.
    touch ${TARGET_4_C_FILE}
    ${MAKE_CMD} ${TARGET_4_TARGET} HASHDEPS_DISABLE=y
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 2

    touch ${TARGET_4_H_FILE}
    ${MAKE_CMD} ${TARGET_4_TARGET} HASHDEPS_DISABLE=y
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 3

    touch ${TARGET_4_D_FILE}
    ${MAKE_CMD} ${TARGET_4_TARGET} HASHDEPS_DISABLE=y
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 4

    # And just to confirm, nothing gets rebuilt if nothing it touched.
    ${MAKE_CMD} ${TARGET_4_TARGET} HASHDEPS_DISABLE=y
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_4_TARGET} 1 4
}

test_basic_c_dependency_generation_many_headers_for_one_c_file()
{
    # Put the source files in place for the test.
    ${MAKE_CMD} output5.tmp_sources

    # Just make the target and confirm everything works.
    ${MAKE_CMD} ${TARGET_5_TARGET}
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_5_TARGET} 1 1

    # Now touch _all_ the header files and confirm nothing is rebuilt.
    touch -- ./*.h
    ${MAKE_CMD} ${TARGET_5_TARGET}
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_5_TARGET} 1 1

    # Finally, disable hashdeps, and everything should still work and since
    # the headers were touched above the target should be rebuilt.
    ${MAKE_CMD} ${TARGET_5_TARGET} HASHDEPS_DISABLE=y
    assertTrue "Make failed for C generation" "$?"
    assert_file_with_x_deps_made_n_times ${TARGET_5_TARGET} 1 2
}

. /usr/bin/shunit2
