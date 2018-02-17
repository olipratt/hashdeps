# Hashdeps

GNU make file which can be included to configure rebuilding of a target based on a dependency's content changing rather than its modification time.

## Use Cases

GNU make decides that a target needs rebuilding if a dependency is 'newer' than the target file. It does this by comparing the modification timestamp of the target and dependency files. However, these timestamps can often change such that make decides a target needs rebuilding when actually nothing has changed. Here are some examples.

### Changing Git Branches

In a git codebase, you:

- build your code
- switch branches, which changes a file's contents, but don't build anything
- checkout the original branch
- build again with the code exactly as it was before.

Since Git commits don't include file timstamps, the checkout of the original branch sets the modification times of any changed files to the current time, so the build through `make` will still trigger rebuilds.


## Requirements

- Should support any version of GNU make.
- Requires the `md5sum` utility to be installed.
- Only has Linux support currently.

## Usage

1. Add the makefile to your project.
  1. Either add this repository as a [git submodule](https://github.com/blog/2104-working-with-submodules) of your Git project, or
  1. just download the `hashdeps.mk` file into a suitable location in your project.
1. Include `hashdeps.mk` from your main `Makefile` - e.g. assuming you put the file in a directory `makefiles/`, add the line:

    ```makefile
    include makefiles/hashdeps.mk
    ```

    Because `hashdeps.mk` defines values that you then reference in your own make rules, it must be included in the process as soon as possible - i.e. at the very top of the main `Makefile`.

## Configuration

The following configuration can be set by users of this utility.

- Set the suffix used for files containing dependency hashes by setting the following variable after including this utility. The suffix must be unique to files created by this utility.

    ```makefile
    HASH_FILE_SUFFIX := .dephash
    ```

## Development

Install `shunit2` and `shellcheck` using your system's package manager.

Run tests with `make test`
