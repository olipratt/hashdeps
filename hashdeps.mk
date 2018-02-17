
# The suffix used for files that contain the hashes of dependencies.
# Can be changed if desired, but must be unique to files created by this
# utility.
HASH_FILE_SUFFIX := .dephash

# INTERNALS -------------------------------------------------------------------
# Users should not change anything below this line.
# -----------------------------------------------------------------------------

# Function to convert a normal dependency to a hashed dependency.
define hash_dep
    $(1)$(HASH_FILE_SUFFIX)
endef

# Make will delete files created by pattern rules by default - prevent this.
.PRECIOUS: %$(HASH_FILE_SUFFIX)

# Check if the file md5sum in the file is still accurate. If not, write an
# updated sum.
# If the file doesn't exist, md5sum returns an error status code, and prints
# some stderr text which we purposely ignore.
%$(HASH_FILE_SUFFIX): %
	@md5sum -c $@ --status 2>/dev/null || md5sum $< > $@
