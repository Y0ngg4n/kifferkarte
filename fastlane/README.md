fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android test

```sh
[bundle exec] fastlane android test
```

Runs all the tests

### android bump_major

```sh
[bundle exec] fastlane android bump_major
```



### android bump_minor

```sh
[bundle exec] fastlane android bump_minor
```



### android bump_patch

```sh
[bundle exec] fastlane android bump_patch
```



### android read_version

```sh
[bundle exec] fastlane android read_version
```



### android read_code

```sh
[bundle exec] fastlane android read_code
```



### android apply_new_version

```sh
[bundle exec] fastlane android apply_new_version
```



### android beta

```sh
[bundle exec] fastlane android beta
```

Submit a new Beta Build to Beta

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Deploy a new version to the Google Play

### android tag_commit

```sh
[bundle exec] fastlane android tag_commit
```



----


## iOS

### ios read_version

```sh
[bundle exec] fastlane ios read_version
```



### ios read_code

```sh
[bundle exec] fastlane ios read_code
```



### ios beta

```sh
[bundle exec] fastlane ios beta
```

Submit a new Beta Build to Beta

### ios browserstack

```sh
[bundle exec] fastlane ios browserstack
```

Upload to BrowserStack Applive

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
