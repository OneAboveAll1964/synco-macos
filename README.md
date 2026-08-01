<div style="display: flex; justify-content: center; width: 100%;">
  <img src="docs/icon-large.png" style="width: 100%; max-width: 100px;" alt="Synco">
</div>

# Synco for macOS - Sync Clipboard Between your Mac and Android Phone

One clipboard shared between your Mac and your Android phone, over your own
network. Copy on one, paste on the other. Text, rich text, links, images and
files, including whole folders from the Finder.

Nothing leaves your local network. There is no account, no server and no cloud.
The two devices find each other by themselves and keep working after a reboot, a
new Wi-Fi network or a changed IP address.

Synco lives in the menu bar. There is no Dock icon and no window in the way.

The Android side lives in
[synco-android](https://github.com/OneAboveAll1964/synco-android).

## How it works

Both devices announce themselves on the local network and connect directly. The
connection is encrypted end to end, and you confirm a short fingerprint once per
device so nobody else can pair with you.

Everything about how the two sides talk is written down in
[PROTOCOL.md](PROTOCOL.md), which is identical in both repositories.

## A note about the Android side

macOS lets an app read the clipboard whenever it likes, so this side simply
works. Android does not: since Android 10 an app can only read the clipboard
while it owns the window you are looking at.

That means the phone has to work harder, and it has two ways to do it. By default
it uses an accessibility service that flashes an invisible window for a few
milliseconds to read a copy, which works everywhere but occasionally misses one.
Optionally it can use Shizuku, which is more reliable and never touches focus but
has to be restarted after each reboot.

None of this affects the Mac. It is worth knowing because if a copy made on the
phone does not appear here, the cause is almost always on that side. The
[Android README](https://github.com/OneAboveAll1964/synco-android) explains the
choice.

## Building

For development:

```bash
swift build
swift test
```

To produce a real app:

```bash
./Scripts/package-app.sh      # builds dist/Synco.app
./Scripts/install.sh          # and copies it to /Applications
```

Use the packaged app rather than the bare binary. macOS only grants local network
access and login-item registration to a proper app bundle, and a loose executable
is not registered with the system, so its menu bar icon is unreliable.

## Installing a release build

The app is signed ad hoc rather than with a paid Apple Developer ID, so the first
launch needs one extra step. Unzip it, drag `Synco.app` to `/Applications`, then
right-click it and choose **Open**. Confirm once and macOS remembers.

If it still refuses, clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine /Applications/Synco.app
```

## First run

1. Open Synco on the Mac and on the phone.
2. Allow the local network prompt the first time. Without it the two devices
   cannot see each other.
3. Each device offers to pair with the other. Approve on both, and check the
   four-block fingerprint matches. That check is what stops someone else on the
   network pairing with you.

If the menu bar icon does not appear, it is probably tucked behind the notch.
Hold ⌘ and drag it somewhere visible; its position is remembered.

## Settings

**Direction.** Per device, in four combinations: both ways, Mac to phone only,
phone to Mac only, or paused. Text, images and files can each be turned on and
off separately in each direction. Changing this on either device changes it on
the other, and a change made while disconnected is applied on the next
connection.

**Where received files go.** `~/Downloads/Synco`, with a Reveal in Finder button
in Settings.

**Largest file.** Anything bigger is refused in both directions. Each device has
its own limit and the smaller of the two wins. Pick **No limit** if you would
rather it never refuse anything.

**Starting Shizuku for a phone.** Shizuku stops every time the phone reboots,
and starting it needs adb. Turn this on and a paired phone that is plugged in
can ask this Mac to run that one command for it. Synco runs nothing else, and
only devices you have already paired can ask. It needs adb on this Mac, from
Homebrew or the Android SDK.

## Why the App Sandbox is off

Synco writes files you receive into a folder you choose and puts file URLs on the
pasteboard so other apps can use them. Under the sandbox both become awkward and
would need entitlements that give away more than they save. The app is signed
with the hardened runtime and asks only for the network access it needs.

## If something is not syncing

- **The devices cannot see each other.** They must be on the same network, and
  some routers stop devices talking to each other. Guest networks usually do. If
  you denied the local network prompt, re-enable Synco under Privacy & Security →
  Local Network.
- **Copies from the phone do not arrive.** That side has the harder job; see the
  note above.
- **A file did not arrive.** It is probably larger than the limit on one of the
  two devices.

## Licence

MIT with an attribution clause. See [LICENSE](LICENSE). You are free to use,
change and redistribute Synco, including in your own products, as long as you
credit the original author somewhere a user or reader can find it.

Made by [OneAboveAll1964](https://github.com/OneAboveAll1964).
