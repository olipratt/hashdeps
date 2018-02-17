
include ../hashdeps.mk

# Every time this rule runs, add another line to the file.
file2.tmp: $(call hash_dep,file1.tmp)
	@echo "Example text" >> $@
