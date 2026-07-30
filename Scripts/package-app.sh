#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"

app_name="Synco"
bundle_id="app.synco"
bundle_dir="$root_dir/dist/$app_name.app"
contents_dir="$bundle_dir/Contents"
info_plist="$root_dir/Resources/Info.plist"
entitlements="$root_dir/Resources/$app_name.entitlements"
icon_file="$root_dir/Resources/$app_name.icns"

swift build -c release --package-path "$root_dir" --product "$app_name"
bin_dir="$(swift build -c release --package-path "$root_dir" --show-bin-path)"

rm -rf "$bundle_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"

install -m 755 "$bin_dir/$app_name" "$contents_dir/MacOS/$app_name"
install -m 644 "$info_plist" "$contents_dir/Info.plist"
printf 'APPL????' > "$contents_dir/PkgInfo"

if [ -f "$icon_file" ]; then
    install -m 644 "$icon_file" "$contents_dir/Resources/$app_name.icns"
fi

codesign --force --sign - --identifier "$bundle_id" --options runtime \
    --entitlements "$entitlements" "$bundle_dir"
codesign --verify --strict "$bundle_dir"

echo "packaged $bundle_dir"
