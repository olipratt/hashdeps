# API -------------------------------------------------------------------------
# Information on using this utility.
# -----------------------------------------------------------------------------
#
# There are two main API functions exposed by this file:
# `hash_deps` and `unhash_deps`
# These are used in make rules to convert dependencies to dependencies on the
# hashes (contents) of those files, and then to convert references to the
# dependency hashes back to the original dependency files.
#
# combined.txt: $(call hash_deps,a.txt b.txt)
#    echo "Concatenating files"
#    cat $(call unhash_deps,$^) > combined.txt
#
# Note that these should not be used on PHONY dependencies, as it makes no
# sense - they are not files that can be hashed, and always cause a target that
# depends on them to be remade.
#
# There is configuration below to let you alter the default behaviour to your
# liking.

# CONFIGURATION ---------------------------------------------------------------
# Users can override any of the following defaults e.g. by setting these
# variables _before_ including this file or passing values at the command line.
# -----------------------------------------------------------------------------

# The suffix used for files that contain the hashes of dependencies.
# Can be changed if desired, but must be unique to files created by this
# utility. It _cannot_ be blank, and should include any starting `.`.
HASHDEPS_HASH_SUFFIX ?= .dephash

# Specify a directory to store hashes in rather than putting them alongside
# dependency files, which could otherwise undesirably pollute the source tree.
# Leave blank to just out hash files alongside dependency files.
# E.g. the following setting would store the hash for `source/file.txt` as
# `hashtree/source/file.txt.dephash`:
# HASHDEPS_HASH_TREE_DIR := hashtree
HASHDEPS_HASH_TREE_DIR ?=

# Set this variable to some non-whitespace value to disable any echoing by
# recipes in this utility.
HASHDEPS_QUIET ?=

# Set this to a non-whitespace value to disable all dependency hashing logic
# from this utility.
HASHDEPS_DISABLE ?=

# INTERNALS -------------------------------------------------------------------
# Users _must not_ change anything below this line!
# -----------------------------------------------------------------------------

# Do any sanity checks on variables up front.
ifeq ($(strip $(HASHDEPS_HASH_SUFFIX)),)
$(error The suffix for dependency hash files (HASHDEPS_HASH_SUFFIX) cannot\
		be blank)
endif

# Either actually echo or just use true, which 'does nothing, successfully'.
ifeq ($(strip $(HASHDEPS_QUIET)),)
HASHDEPS_ECHO := echo
else
HASHDEPS_ECHO := true
endif

# Only if the value is non-empty, make sure it ends in a forward slash so
# another directory or filename can be appended correctly.
HASHDEPS_HASH_TREE_SANITISED = \
	$(addsuffix /,$(strip $(HASHDEPS_HASH_TREE_DIR)))

# Function to convert a normal dependency to a hashed dependency.
# Takes one argument - a space separated list of dependencies to convert.
define hash_deps
    $(if $(HASHDEPS_DISABLE),\
		$(1),\
		$(patsubst %,\
			$(HASHDEPS_HASH_TREE_SANITISED)%$(HASHDEPS_HASH_SUFFIX),\
			$(1)))
endef

# Function that undoes the transformations above, so lets you access the
# true dependency files in recipes.
# Takes one argument - a space separated list of dependencies to convert.
define unhash_deps
    $(if $(HASHDEPS_DISABLE),\
		$(1),\
		$(patsubst $(HASHDEPS_HASH_TREE_SANITISED)%$(HASHDEPS_HASH_SUFFIX),\
			%,\
			$(1)))
endef

# Make will delete files created by pattern rules by default - prevent this.
.PRECIOUS: %$(HASHDEPS_HASH_SUFFIX)

# Check if the file md5sum in the file is still accurate. If not, write an
# updated sum.
# If the file doesn't exist, md5sum returns an error status code, and prints
# some stderr text which we purposely ignore.
$(HASHDEPS_HASH_TREE_SANITISED)%$(HASHDEPS_HASH_SUFFIX): %
	@mkdir -p $(dir $@)
	@curr_hash=$$(md5sum "$<" | cut -f 1 -d " ") && \
		{ [ -f $@ ] && \
			[ "$$(cat "$@")" = "$${curr_hash}" ] && \
			$(HASHDEPS_ECHO) "Hash file still up to date: $@" ;} || \
		{ $(HASHDEPS_ECHO) "Updating hash file: $@" && \
			echo -n "$${curr_hash}" > $@ ; }

# A 'clean' target that removes any generated hash files.
# Delete any files with the unique hash file suffix, either anywhere in the
# current directory or in the HASH_TREE_DIR if set.
# Purposely echo the clean command so users can see what is being deleted.
HASHDEPS_CLEAN_DIR = \
	$(if $(HASHDEPS_HASH_TREE_SANITISED),$(HASHDEPS_HASH_TREE_SANITISED),.)
HASHDEPS_CLEAN_CMD = \
	find $(HASHDEPS_CLEAN_DIR) -name "*$(HASHDEPS_HASH_SUFFIX)" -delete
.PHONY: hashdeps_clean
hashdeps_clean:
	@$(HASHDEPS_ECHO) "Removing all dependency file hashes"
	$(HASHDEPS_CLEAN_CMD)
