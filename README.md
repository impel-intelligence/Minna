# Iris

## Build Instructions
The impel project uses the [Tuist](https://tuist.io/) build system. The steps to build the project are below.

### Install Mise
Since Tuist is exclusively available on [Mise](https://mise.jdx.dev), follow the [getting started](https://mise.jdx.dev/getting-started.html) guide to install it. 

Once you have mise installed, run the following command to install Tuist, [swiftlint](https://github.com/realm/swiftlint), and [swiftformat](https://github.com/nicklockwood/swiftformat).
```shell
mise install
```

### Generate XCode Project
To generate an actual xcode project to work in, run the following tuist commands:

```shell
tuist install
tuist generate
```
