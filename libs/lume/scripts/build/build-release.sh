#!/bin/sh

pushd ../../

swift build -c release --product lume
codesign --force --entitlement ./resources/lume.entitlements --sign - .build/release/lume

mkdir -p ./.release
cp -f .build/release/lume ./.release/lume

# Install to user-local bin directory (standard location)
USER_BIN="$HOME/.local/bin"
mkdir -p "$USER_BIN"
cp -f ./.release/lume "$USER_BIN/lume"

# Advise user to add to PATH if not present
if ! echo "$PATH" | grep -q "$USER_BIN"; then
  echo "[lume build] Note: $USER_BIN is not in your PATH. Add 'export PATH=\"$USER_BIN:\$PATH\"' to your shell profile."
fi

popd