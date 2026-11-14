#!/usr/bin/env bash
# Device (iphoneos) Release build of vanillara, packaged as an unsigned IPA.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${IOS_BUILD_DIR:-$repo_root/build/ios}"
ipa_path="${IOS_IPA_PATH:-$repo_root/build/RedAlert-ios-unsigned.ipa}"

cmake -S "$repo_root" -B "$build_dir" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphoneos \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=NO \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="" \
    -DBUILD_VANILLATD=OFF \
    -DBUILD_VANILLARA=ON \
    -DBUILD_REMASTERTD=OFF \
    -DBUILD_REMASTERRA=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_TOOLS=OFF \
    -DNETWORKING=OFF \
    -DOPENAL=ON \
    -DSDL2=ON

cmake --build "$build_dir" --config Release --target VanillaRA -- \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY=""

app="$(find "$build_dir" -type d -path '*Release-iphoneos/*.app' -print -quit)"
if [[ -z "$app" ]]; then
    echo "No Release-iphoneos .app was produced" >&2
    find "$build_dir" -name '*.app' -print >&2 || true
    exit 1
fi

bin="$app/vanillara"
if [[ ! -f "$bin" ]]; then
    echo "App bundle has no vanillara executable: $app" >&2
    find "$app" -maxdepth 2 -print >&2
    exit 1
fi

echo "App bundle: $app"
file "$bin"
if ! file "$bin" | grep -q 'arm64'; then
    echo "Executable is not arm64" >&2
    exit 1
fi

plutil -extract CFBundleIdentifier raw -o - "$app/Info.plist"
plutil -extract UIFileSharingEnabled raw -o - "$app/Info.plist" | grep -qx true
plutil -extract LSSupportsOpeningDocumentsInPlace raw -o - "$app/Info.plist" | grep -qx true
plutil -extract MinimumOSVersion raw -o - "$app/Info.plist"
plutil -extract UIStatusBarHidden raw -o - "$app/Info.plist" | grep -qx true

# Unsigned payload. 全能签 re-signs this; there must be no paid-account entitlement.
rm -rf "$app/_CodeSignature"
stage="$(mktemp -d)"
mkdir -p "$stage/Payload"
cp -R "$app" "$stage/Payload/"
rm -f "$ipa_path"
mkdir -p "$(dirname "$ipa_path")"
(cd "$stage" && zip -qry "$ipa_path" Payload)
rm -rf "$stage"

echo "IPA: $ipa_path"
ls -lh "$ipa_path"
shasum -a 256 "$ipa_path"
