#! /bin/bash

log()
{
    echo "$@"
}

clean_tmp_files()
{
    log "Cleaning tmp files..."
    rm -fv *.tmp
}

setUp()
{
    clean_tmp_files
}

tearDown()
{
    clean_tmp_files
}


test_example()
{
    # Make the file, which will create it with one line.
    touch file1.tmp
    make -f mainline.mk file2.tmp
    assertEquals "First make failed" $(wc -l < file2.tmp) 1

    # Touch the dependency and re-make the file - it should be unchanged.
    touch file1.tmp
    make -f mainline.mk file2.tmp
    assertEquals "Second make failed" $(wc -l < file2.tmp) 1
}


. shunit2
