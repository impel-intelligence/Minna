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

## Project Tooling
This project come swith a couple of tools for managing code quality.

### Formatting
To format **and change** invalid files, you can run the `format` command.

```shell
mise run format
```

To format and **not change** invalid files, you can run the `format-lint` command.

```shell
mise run format-lint
```

### Linting
To lint the codebase you can run the `lint` command. This will not change any files. This command is also run on every XCode build, so you will see warnings populated directly into xcode.

```shell
mise run lint
```

To auto-fix linting issues, you can run the `lint-fix` command.

```shell
mise run lint-fix
```
