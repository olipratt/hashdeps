#! /bin/bash

# For the tests, disable makefiles from printing their working directory as it
# produces too much stdout spam.
export MAKEFLAGS+=--no-print-directory

log()
{
    echo "$@"
}

clean_tmp_files()
{
    log "Cleaning tmp files..."
    rm -fv *.tmp
    rm -fv *.dephash
}

setUp()
{
    clean_tmp_files
}

tearDown()
{
    clean_tmp_files
}


test_touch_means_no_remake()
{
    # Make the file, which will create it with one line.
    touch file1.tmp
    make -f mainline.mk file2.tmp
    assertEquals "First make failed" 1 $(wc -l < file2.tmp)

    # Touch the dependency and re-make the file - it should be unchanged.
    touch file1.tmp
    make -f mainline.mk file2.tmp
    assertEquals "Second make failed" 1 $(wc -l < file2.tmp)
}


test_edit_means_remake()
{
    # Make the file, which will create it with one line.
    touch file1.tmp
    make -f mainline.mk file2.tmp
    assertEquals "First make failed" 1 $(wc -l < file2.tmp)

    # Touch the dependency and re-make the file - it should be unchanged.
    echo "text" > file1.tmp
    make -f mainline.mk file2.tmp
    assertEquals "Second make failed" 2 $(wc -l < file2.tmp)
}



. shunit2
