#!/usr/bin/env bash
set -euo pipefail

read_version() {
  awk '$1 == "version:" { print $2; exit }' "$1"
}

dart_version=$(read_version dart/pubspec.yaml)
flutter_version=$(read_version flutter/pubspec.yaml)
flutter_dart_dependency=$(
  awk '$1 == "vodozemac:" { print $2; exit }' flutter/pubspec.yaml
)

if [[ "$dart_version" != "$flutter_version" ]]; then
  echo "Dart package version $dart_version does not match Flutter package version $flutter_version."
  exit 1
fi

if [[ "$flutter_dart_dependency" != "$dart_version" ]]; then
  echo "flutter_vodozemac depends on vodozemac $flutter_dart_dependency, expected $dart_version."
  exit 1
fi

if [[ "${GITHUB_REF_TYPE:-}" == "tag" ]]; then
  tag_version=${GITHUB_REF_NAME#v}
  if [[ "$tag_version" != "$dart_version" ]]; then
    echo "Git tag $GITHUB_REF_NAME does not match package version $dart_version."
    exit 1
  fi
fi

echo "Package versions are synchronized at $dart_version."
