# Makefile containing all rules used for unit test targets.

# Disable all make's default implicit rules so its debug output is more usable.
.SUFFIXES:

# The hashdeps makefile is in the parent directory of this file - this file's
# location will be the last file in the MAKEFILE_LIST variable.
include $(dir $(lastword $(MAKEFILE_LIST)))../hashdeps.mk

# Every time this rule runs, add another copy of source to the output file.
output1.tmp: $(call hash_deps,source1.tmp)
	@cat $(call unhash_deps,$^) >> $@

# Same as above, except two hashed dependencies.
output2.tmp: $(call hash_deps,source1.tmp source2.tmp)
	@cat $(call unhash_deps,$^) >> $@

# With only some dependencies hashed, show that make's built in variables used
# to reference all dependencies of a recipe can safely be unhashed.
output3.tmp: $(call hash_deps,source1.tmp) source2.tmp
	@cat $(call unhash_deps,$^) >> $@
