
# The suffix used for files that contain the hashes of dependencies.
# Can be changed if desired, but must be unique to files created by this
# utility.
HASH_FILE_SUFFIX = .dephash

# Specify a directory to store hashes in rather than putting them alongside
# dependency files, which could otherwise undedsirably pollute the source tree.
# Leave blank to just out hash files alongside dependency files.
HASH_FILE_TREE_DIR =

# Set this variable to some non-whitespace value to disable any echoing by
# recipes in this utility.
HASHDEPS_QUIET =

# INTERNALS -------------------------------------------------------------------
# Users should not change anything below this line.
# -----------------------------------------------------------------------------

# Either actually echo or just use true, which 'does nothing, successfully'.
ifeq ($(strip $(HASHDEPS_QUIET)),)
HASHDEPS_ECHO := echo
else
HASHDEPS_ECHO := true
endif

# Only if the value is non-empty, make sure it ends in a forward slash so
# another directory or filename can be appended correctly.
HASH_FILE_TREE_SANITISED = $(addsuffix /,$(strip $(HASH_FILE_TREE_DIR)))

# Function to convert a normal dependency to a hashed dependency.
# Takes one argument - the dependency to convert.
define hash_dep
    $(HASH_FILE_TREE_SANITISED)$(1)$(HASH_FILE_SUFFIX)
endef

# Only call out to create the directory in the separate directory tree if
# there is one in use, to avoid unnecessary work.
ifneq ($(HASH_FILE_TREE_SANITISED),)
define hash_file_tree_dir_create =
mkdir -p $(dir $@)
endef
else
define hash_file_tree_dir_create =
endef
endif

# Make will delete files created by pattern rules by default - prevent this.
.PRECIOUS: %$(HASH_FILE_SUFFIX)

# Check if the file md5sum in the file is still accurate. If not, write an
# updated sum.
# If the file doesn't exist, md5sum returns an error status code, and prints
# some stderr text which we purposely ignore.
$(HASH_FILE_TREE_SANITISED)%$(HASH_FILE_SUFFIX): %
	@$(hash_file_tree_dir_create)
	@ { md5sum -c $@ --status 2>/dev/null && \
		$(HASHDEPS_ECHO) "Hash file still up to date: $@" ;} || \
		{ $(HASHDEPS_ECHO) "Updating hash file: $@" && md5sum $< > $@; }
