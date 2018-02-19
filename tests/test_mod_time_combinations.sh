#! /bin/bash
# Tests of various modification time combinations of the dependency, target,
# and hash files.
# The tests here should give coverage of all the cases.
# The table below shows:
# - in the first 3 columns, all the possible combinations of modification times
#   of the Target file, Hash file, and Dependency file, simplified to '0' for
#   current time, '-1' for e.g. '1 second ago' and '-2' for e,g, '2 seconds
#   ago'.
# - In the fourth column - whether the dependency's content has actually been
#   edited since the target was built, so a re-make should regenerate the
#   target file.
# - The fifth and sixth columns show the behaviour of targets with hashed
#   dependencies under the default configuration - covering whether the hash
#   file is regenerated and whether the target is regenerated, with an '!' in
#   the target regenetation column if the target is or isn't regenerated when
#   to be completely correct the opposite action should be taken.
# - The seventh and eigth columns show the same for the behaviour when the
#   configuration option `HASHDEPS_FORCE_HASH` is set to force hash generation
#   of dependencies on every build.
#
# In each case, it's assumed that the hash file is stored with the target
# and it is always correct that the target was made with the dependency
# contents matching the hash. This must be true because the hash is created as
# part of creating the target.
# The case of the target somehow changing, but the hash and dependency content
# still matching is not considered at all as a case to handle.
#
# | Tgt | Hash | Dep | Dep | Default: | Default: | Force: | Force:  |
# |     |      |     | Ed? | Regen    | Regen    | Regen  | Regen   |
# |     |      |     |     | Hash?    | Target?  | Hash?  | Target? |
# |-----|------|-----|-----|----------|----------|--------|---------|
# | 0   | -1   | -2  | N   | N        | N        | Y      | N       |
# | 0   | -1   | -2  | Y   | N        | N!       | Y      | Y       |
# | 0   | -2   | -1  | N   | Y        | N        | Y      | N       |
# | 0   | -2   | -1  | Y   | Y        | Y        | Y      | Y       |
# | -1  | 0    | -2  | N   | N        | Y!       | Y      | N       |
# | -1  | 0    | -2  | Y   | N        | Y        | Y      | Y       |
# | -1  | -2   | 0   | N   | Y        | N        | Y      | N       |
# | -1  | -2   | 0   | Y   | Y        | Y        | Y      | Y       |
# | -2  | 0    | -1  | N   | N        | Y!       | Y      | N       |
# | -2  | 0    | -1  | Y   | N        | Y        | Y      | Y       |
# | -2  | -1   | 0   | N   | Y        | Y!       | Y      | N       |
# | -2  | -1   | 0   | Y   | Y        | Y        | Y      | Y       |
#
# From the above, the things to take away are:
# - The force case always regenerates the target if-and-only-if the dependency
#   has changed, at the cost of always regenerating the file hash.
# - The default behaviour only doesn't behave correctly when:
#   - The target file has an older modification time than the hash, which
#     should not happen if the hash and target file are stored together.
#   - The dependency has been modified but still has an older modification
#     time, which shouldn't happen if its modification time only increases
#     (e.g. if files are only ever replaced with changed versions at the
#     current timestampt such as when `git checkout` runs).
# - The default behaviour avoids recalculating file hashes in many situations
#   making it more efficient, at the cost of handling the special cases
#   outlined above correctly.

. ./utils.sh

# shunit2 function called before each test.
set_up_table_driven_test()
{
    # Run all tests in a tmp dir. This way there's no need to clean up at the
    # end because the tmp dir is cleaned up by shunit2 itself.
    cd "${SHUNIT_TMPDIR}" || exit

    # Clean any lingering files before a test.
    clean_tmp_files

    # Put some initial source files used by rules in place.
    echo "example source line" >> "${TARGET_1_DEPENDENCY}"

    # Make the target so that it and the hash file exists as all tests here
    # require it.
    ${MAKE_CMD} ${TARGET_1_TARGET}
}

set_target_hash_dep_files_modification_time_order()
{
    local target_order=$1
    local hash_order=$2
    local dep_order=$3

    assertEquals "Ordering values should be one of 0, -1, -2" 1 \
        "$(( target_order == 0 || target_order == -1 || target_order ==-2 ))"
    assertEquals "Ordering values should be one of 0, -1, -2" 1 \
        "$(( hash_order == 0 || hash_order == -1 || hash_order ==-2 ))"
    assertEquals "Ordering values should be one of 0, -1, -2" 1 \
        "$(( dep_order == 0 || dep_order == -1 || dep_order == -2 ))"

    # Making the gap one minute long should be plenty as these touch operations
    # will only take fractions of a second.
    touch -d "$((target_order * -1)) minutes ago" ${TARGET_1_TARGET}
    touch -d "$((hash_order * -1)) minutes ago" ${TARGET_1_HASH_FILE}
    touch -d "$((dep_order * -1)) minutes ago" ${TARGET_1_DEPENDENCY}
}

run_single_table_test()
{
    local target_order=$1
    local hash_order=$2
    local dep_order=$3
    local dep_edit=$4
    local target_remade=$5
    local hashdeps_force=$6

    echo "Running table subtest: ${target_order} ${hash_order} ${dep_order}" \
        "${dep_edit} ${target_remade} ${hashdeps_force}"

    set_up_table_driven_test

    # If required for this test, modify the dependency such that the target
    # really should be regenerated.
    if [ "${dep_edit}" = "Y" ]
    then
        edit_file_to_force_remake ${TARGET_1_DEPENDENCY}
    fi

    # Now set the modification time ordering of the files as required for this
    # specific test and run the make command.
    set_target_hash_dep_files_modification_time_order \
        "${target_order}" "${hash_order}" "${dep_order}"

    ${MAKE_CMD} ${TARGET_1_TARGET} HASHDEPS_FORCE_HASH="${hashdeps_force}"

    # Now check that the target was or wasn't remade as expected.
    if [ "${target_remade}" = "Y" ]
    then
        assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 2
    else
        assert_file_with_x_deps_made_n_times ${TARGET_1_TARGET} 1 1
    fi
}

# -----
# Tests
# -----

test_default_behaviour_for_all_modification_time_combinations()
{
    # The lines of the table below match the more human readable version in the
    # comments above, and this logic executes simple tests to confirm it.
    while read -r target_order hash_order dep_order dep_edit target_remade; do
        run_single_table_test "${target_order}" "${hash_order}" "${dep_order}"\
            "${dep_edit}" "${target_remade}"
    done <<EOF
0  -1 -2 N N
0  -1 -2 Y N
0  -2 -1 N N
0  -2 -1 Y Y
-1  0 -2 N Y
-1  0 -2 Y Y
-1 -2  0 N N
-1 -2  0 Y Y
-2  0 -1 N Y
-2  0 -1 Y Y
-2 -1  0 N Y
-2 -1  0 Y Y
EOF
}

test_force_behaviour_for_all_modification_time_combinations()
{
    # The lines of the table below match the more human readable version in the
    # comments above, and this logic executes simple tests to confirm it.
    while read -r target_order hash_order dep_order dep_edit target_remade; do
        run_single_table_test "${target_order}" "${hash_order}" "${dep_order}"\
            "${dep_edit}" "${target_remade}" Y
    done <<EOF
0  -1 -2 N N
0  -1 -2 Y Y
0  -2 -1 N N
0  -2 -1 Y Y
-1  0 -2 N N
-1  0 -2 Y Y
-1 -2  0 N N
-1 -2  0 Y Y
-2  0 -1 N N
-2  0 -1 Y Y
-2 -1  0 N N
-2 -1  0 Y Y
EOF
}

. /usr/bin/shunit2
