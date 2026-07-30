#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"

app_name="Synco"
source_bundle="$root_dir/dist/$app_name.app"
applications_dir="/Applications"
target_bundle="$applications_dir/$app_name.app"

"$script_dir/package-app.sh"

if [ ! -w "$applications_dir" ]; then
    echo "$applications_dir is not writable; re-run this script with sudo" >&2
    exit 1
fi

if pgrep -x "$app_name" >/dev/null 2>&1; then
    osascript -e "tell application \"$app_name\" to quit" >/dev/null 2>&1 || true
    sleep 1
    pkill -x "$app_name" >/dev/null 2>&1 || true
fi

rm -rf "$target_bundle"
ditto "$source_bundle" "$target_bundle"
echo "installed $target_bundle"

if [ ! -t 0 ]; then
    echo "non-interactive shell: skipping the login item"
    exit 0
fi

printf 'Open %s automatically at login? [y/N] ' "$app_name"
read -r answer

case "$answer" in
    y|Y|yes|Yes)
        osascript -e "tell application \"System Events\" to delete login item \"$app_name\"" \
            >/dev/null 2>&1 || true
        osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$target_bundle\", hidden:true}" \
            >/dev/null
        echo "registered the login item"
        ;;
    *)
        echo "skipped the login item; you can turn it on later in Synco Settings"
        ;;
esac

open "$target_bundle"
