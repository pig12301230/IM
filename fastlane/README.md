fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios unit_tests

```sh
[bundle exec] fastlane ios unit_tests
```

Run unit tests, without build app.

### ios build_only

```sh
[bundle exec] fastlane ios build_only
```

只是測試 app 是否能正常地被 build 起來

### ios release_adhoc

```sh
[bundle exec] fastlane ios release_adhoc
```



### ios release_UAT

```sh
[bundle exec] fastlane ios release_UAT
```



----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
