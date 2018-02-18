#! /bin/bash
# Test utilities and common constants.

# The basic make command with any standard arguments.
# For the tests, disable makefiles from printing their working directory as it
# produces too much stdout spam.
# Also disable any makeflags in case e.g. tests are being run through make.
export MAKEFLAGS=
export MAKE_CMD="make -f ${PWD}/mainline.mk --no-print-directory"

# The default suffix used for dependency hashes.
export DEFAULT_HASH_FILE_SUFFIX=.dephash
# A simple name to use for a separate directory to store hashes if needed.
export HASH_DIR_NAME=hashes

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
    rm -f -- *.tmp *"${DEFAULT_HASH_FILE_SUFFIX}"
    rm -fr -- "${HASH_DIR_NAME}"
}

# Edit a file's contents so it will require anything depending to be remade.
edit_file_to_force_remake()
{
    local filename=$1
    # Just add a `-` character after every character in the file.
    sed -i 's/./&-/g' "${filename}"
}

# Return success only if there are any hash files in the given directory.
any_hash_files_in_dir()
{
    local dir=$1
    # This finds any hash files and passes them to grep which will return
    # success if there are any files, and failure if there are none.
    find "${dir}" -name "*${DEFAULT_HASH_FILE_SUFFIX}" | grep -q '.'
    return $?
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
