#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
signing_identity="${OMNIWM_SIGNING_IDENTITY:-LocalDevCert}"
if ! security find-identity -v -p codesigning | grep -Fq "\"$signing_identity\""; then
    echo "Missing valid code-signing identity '$signing_identity'. See docs/personal-wm/native-integration.md#vaste-ontwikkelrechten." >&2
    exit 1
fi
OMNIWM_APP_NAME="OmniWM Dev" \
OMNIWM_BUNDLE_ID="com.barut.OmniWM.dev" \
OMNIWM_SIGNING_IDENTITY="$signing_identity" \
MAKEFLAGS="SWIFT=swift" \
    "${SWIFTLY_HOME_DIR:-$HOME/.swiftly}/bin/swiftly" run ./Scripts/package-app.sh debug dev

# Preserve the executable's entitlements while sealing the complete development bundle.
codesign --force --deep --preserve-metadata=entitlements \
    --sign "$signing_identity" "$ROOT_DIR/dist/OmniWM Dev.app"
codesign --verify --deep --strict "$ROOT_DIR/dist/OmniWM Dev.app"

# Seed isolated data once. Rebuilds must preserve any later development settings.
config_dir="$ROOT_DIR/.cache/personal-wm-dev/config/omniwm-dev"
state_dir="$ROOT_DIR/.cache/personal-wm-dev/state/omniwm-dev"
mkdir -p "$config_dir" "$state_dir"
chmod 700 "$config_dir" "$state_dir"
if [ ! -e "$config_dir/settings.toml" ]; then
    install -m 600 "${XDG_CONFIG_HOME:-$HOME/.config}/omniwm/settings.toml" "$config_dir/settings.toml"
fi
source_state="${XDG_STATE_HOME:-$HOME/.local/state}/omniwm/runtime-state.json"
if [ ! -e "$state_dir/runtime-state.json" ] && [ -f "$source_state" ]; then
    install -m 600 "$source_state" "$state_dir/runtime-state.json"
fi
# Refresh the /Applications copy when installed there; the running instance keeps its old binary until restart.
if [ -d "/Applications/OmniWM Dev.app" ]; then
    rm -rf "/Applications/OmniWM Dev.app"
    ditto "$ROOT_DIR/dist/OmniWM Dev.app" "/Applications/OmniWM Dev.app"
fi
echo "Prepared OmniWM Dev with isolated config and state. Nothing was started."
