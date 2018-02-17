# Hashdeps

GNU make file which can be included to configure rebuilding of a target based on a dependency's content changing rather than its modification time.

A good parallel to draw is [ccache](https://ccache.samba.org/), except this works for all build targets, not just C files.

## Use Cases

GNU make decides that a target needs rebuilding if a dependency is 'newer' than the target file. It does this by comparing the modification timestamp of the target and dependency files. However, these timestamps can often change such that make decides a target needs rebuilding when actually nothing has changed. Here are some examples.

### Changing Git Branches in a Local Clone

In a git codebase, you:

- build your code
- switch branches, which changes a file's contents, but don't build anything
- checkout the original branch
- build again with the code exactly as it was before.

Since Git commits don't include file timstamps, the checkout of the original branch sets the modification times of any changed files to the current time, so the build through `make` will still trigger rebuilds.

### CI System Caching/Passing Built Objects Between Instances

Suppose you have a CI system that builds objects and can cache the objects between builds of the same type, or passes a partially built source tree between stages. Each time the CI system starts a build, the source files may have been re-checked out from version control, so may have newer modification times on disk than the built files. In this case, it's preferable that make checks the content of the source files is the same as when the objects were built, rather than file modification times.

## Requirements

- Should support any version of GNU make.
- Requires the `md5sum` utility to be installed.
- Only has Linux support currently, and only tested with the `bash` shell.

## Usage

1. Add the makefile to your project.
  1. Either add this repository as a [git submodule](https://github.com/blog/2104-working-with-submodules) of your Git project, or
  1. just download the `hashdeps.mk` file into a suitable location in your project.
1. Include `hashdeps.mk` from your main `Makefile` - e.g. assuming you put the file in a directory `makefiles/`, add the line:

    ```makefile
    include makefiles/hashdeps.mk
    ```

    Because `hashdeps.mk` defines values that you then reference in your own make rules, it must be included in the process as soon as possible - i.e. at the very top of the main `Makefile`.

### More Information on Usage

- This utility takes the [md5sum](https://linux.die.net/man/1/md5sum) of dependencies to determine if they have changed, and should be sufficiently unique for most use cases.

- While this utility helps speed up build times in the main uses cases covered above, in completely clean builds there will be the overhead of computing hashes on top of any usual building work and so these will almost certainly be some amount slower.

## Configuration

The following configuration can be set by users of this utility.

- Set the suffix used for files containing dependency hashes by setting the following variable after including this utility. The suffix must be unique to files created by this utility.

    ```makefile
    HASH_FILE_SUFFIX := .dephash
    ```

- Store file hashes in a separate directory tree (e.g. to avoid polluting the source tree) - otherwise by default hashes are stored in files alongside the dependency files.

    ```makefile
    HASH_FILE_TREE_DIR := hashtree
    ```

## Simple Examples

See the unit test files for some examples of this utility in use.

## Development

Install `shunit2` and `shellcheck` using your system's package manager.

Run tests with `make test`
