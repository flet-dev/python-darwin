# Python for Android

Scripts and CI jobs for building Python 3 for iOS.

* Must be run on macOS.
* Build Python 3.13 - specific or the last minor version.
* Creates Python installation with a structure suitable for https://github.com/flet-dev/mobile-forge

## Usage

To build the latest minor version of Python 3.13 for selected iOS ABI:

```
./build.sh 3.13 arm64-apple-ios
```

To build all ABIs:

```
./build-all.sh 3.13
```

## Credits

Build process depends on:
* https://github.com/beeware/cpython-apple-source-deps