# wowcare

A new Flutter project.

## Environment shortcuts

This project already reads the build-time environment from `ENVIRONMENT` using `String.fromEnvironment(...)`.

Use the `=` form for `dart-define`:

```bash
flutter run --dart-define=ENVIRONMENT=UAT
flutter run --dart-define=ENVIRONMENT=LOCAL
flutter build apk --release --dart-define=ENVIRONMENT=UAT
flutter build apk --release --dart-define=ENVIRONMENT=LOCAL
```

To avoid repeating those flags, use the included `Makefile` shortcuts:

```bash
make uat-run
make local-run
make uat-build
make local-build
make uat-appbundle
make local-appbundle
make uat-ios
make local-ios
make uat-ipa
make local-ipa
```

If you want a shell command that looks like `uat run` or `local build apk --release`, add these functions to your `~/.zshrc`:

```bash
uat() {
  local action="${1:?usage: uat <run|build> [args...]}"
  shift

  if [[ "$action" == "run" ]]; then
    flutter run --dart-define=ENVIRONMENT=UAT "$@"
  elif [[ "$action" == "build" ]]; then
    flutter build "$@" --dart-define=ENVIRONMENT=UAT
  else
    echo "usage: uat <run|build> [args...]"
    return 1
  fi
}

local() {
  local action="${1:?usage: local <run|build> [args...]}"
  shift

  if [[ "$action" == "run" ]]; then
    flutter run --dart-define=ENVIRONMENT=LOCAL "$@"
  elif [[ "$action" == "build" ]]; then
    flutter build "$@" --dart-define=ENVIRONMENT=LOCAL
  else
    echo "usage: local <run|build> [args...]"
    return 1
  fi
}
```

Then reload your shell with `source ~/.zshrc` and run:

```bash
uat run
local run
uat build apk --release
local build apk --release
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
