#! /bin/bash
# Tests of multiple dependencies and combinations of dependency types.

. utils.sh

# Define all the targets and their dependencies here.
TARGET_2_TARGET=output2.tmp
TARGET_2_DEPENDENCIES=(source1.tmp source2.tmp)

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
    for source_file in "${TARGET_2_DEPENDENCIES[@]}"
    do
        echo "example source line" >> "${source_file}"
    done
}

# When a file is made, it gains a line of content, so use that to check how
# many times a file has been made.
assert_file_with_x_deps_made_n_times()
{
    local filename=$1
    local x=$2
    local n=$3
    local num_lines
    num_lines=$(wc -l < "${filename}")
    local times_made=$(( num_lines / x ))
    assertEquals "made ${times_made} times instead" "${n}" "${times_made}"
}

test_touch_means_no_remake_two_deps()
{
    # Make the file, which will create it with one line.
    ${MAKE_CMD} ${TARGET_2_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_2_TARGET} 2 1

    # Touch the dependencies and re-make the file - it should be unchanged.
    touch "${TARGET_2_DEPENDENCIES[@]}"
    ${MAKE_CMD} ${TARGET_2_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_2_TARGET} 2 1
}

test_edit_means_remake_two_deps()
{
    # Make the file, which will create it with one line.
    ${MAKE_CMD} ${TARGET_2_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_2_TARGET} 2 1

    # Edit a dependency and re-make the file - it should be updated.
    edit_file_to_force_remake "${TARGET_2_DEPENDENCIES[0]}"
    ${MAKE_CMD} ${TARGET_2_TARGET}
    assert_file_with_x_deps_made_n_times ${TARGET_2_TARGET} 2 2
}

. /usr/bin/shunit2
