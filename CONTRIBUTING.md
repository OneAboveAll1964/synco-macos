# Contributing to Synco for macOS

This repository is one half of a two-repository system. The other half is `synco-android`.
[PROTOCOL.md](PROTOCOL.md) is the contract between them and exists identically in both
repositories. Everything here follows from that.

---

## Conventions

**No comments. None.** Not line comments, not block comments, not doc comments, not
`MARK:` sections, not file headers, not `TODO` or `FIXME`. This applies to Swift, to the
plist and entitlements files, and to the shell scripts. If a piece of code needs a comment
to be understood, rename it or split it until it does not. A comment in a diff is a defect,
not a style preference.

**Small files.** Target under 120 lines, hard ceiling 200. When a type grows past that, find
a real seam and split along it into another file in the same directory — usually an
extension file named `Type+Aspect.swift`. `PeerSession` is split into `+Handshake`,
`+Pairing`, `+Keepalive`, `+Lifecycle`, and `+ReceiveLoop` for exactly this reason. Do not
split arbitrarily to satisfy the line count; if there is no seam, the type is doing too much.

**One primary type per file, named after the file.** `Backoff.swift` contains `Backoff`.
Small supporting types (a private enum used by one method, a nested `CodingKeys`) live with
their owner.

**Components, not god objects.** Each type has one responsibility. Depend on protocols where
a sibling would otherwise be hardcoded: `SyncoSync` reaches transport through
`ClipTransmitting`, the clipboard through `ClipboardApplying`, trust through
`TrustedPeerProviding`, and pairing approval through `PairingApprovalProviding`. This is what
makes the test targets able to substitute fakes without a mocking framework.

**No placeholders.** No stubs that throw "not implemented", no sample code, no demo paths.
Everything committed is working production code.

---

## Target boundaries

Dependencies flow one way. Before adding an `import`, check that it does not create an edge
that is not already in the graph in [README.md](README.md).

### SyncoCore

The wire contract, expressed as pure values. No `Network`, no `AppKit`, no `CryptoKit`, no
file system, no clock. Constants, `DeviceID`, `Fingerprint`, base32 and hex codecs, the
length-prefixed frame codec, `BlobChunk`, every `ControlMessage`, and `ClipCanonicalHash`.

If it is named in PROTOCOL.md as a constant, key, byte layout, or algorithm, it belongs
here. If it needs an actor, it does not.

### SyncoCrypto

Key material and the primitives operating on it: `DeviceIdentity`, `IdentityKeychainStore`,
`EphemeralKeyPair`, `Handshake`, `SessionCipher`, `CryptoPrimitives`. Depends on `SyncoCore`
for constants and encodings.

No sockets here. `Handshake` produces and consumes bytes; it does not know what carries them.

### SyncoTransport

Everything between a socket and a decrypted `ControlMessage`. `FramedConnection` wraps an
`NWConnection` and does length-prefixed reads and writes. `PeerSession` runs the handshake,
the pairing exchange, keepalive, and the receive loop, and publishes `SessionEvent`.
`SyncoListener` and `SyncoDialer` create connections. `Backoff` is here because reconnect is
a transport concern.

`PeerSession` knows nothing about clipboards, settings files, or the UI. Trust and approval
arrive through the `TrustedPeerProviding` and `PairingApprovalProviding` protocols.

### SyncoDiscovery

Bonjour and only Bonjour: `BonjourAdvertiser`, `BonjourBrowser`, `TXTRecordCodec`,
`ServiceAdvertisement`, `DiscoveredPeer`, and `PathMonitorService`. It emits
`DiscoveryEvent`; it never dials. Deciding what to do about a discovered peer belongs to
`SyncoSync`.

### SyncoTransfer

Blob streaming and the file system: staging, chunking, SHA-256 verification, `BlobSizeLimit`,
`TransferPaths`, filename sanitising and collision handling, and `TransferProgress`. It has
no idea a clip exists — it moves named byte streams with digests.

### SyncoClipboard

`NSPasteboard` in both directions. Reading a capture into an ordered representation list,
demoting oversized inline representations to blobs, writing a representation list back onto
the pasteboard, and the `SuppressionWindow` that stops the two devices echoing each other. It
depends on `SyncoTransfer` because staging a pasteboard image is a transfer concern.

Platform-specific pasteboard type mapping lives here and nowhere else.

### SyncoSettings

Persisted user state: `SettingsDocument` and its JSON file, `SettingsStore` as the single
writer, `TrustedPeerRecord`, `PeerDirectionPolicy`, `SyncPolicy`, and `LaunchAtLogin`.

`SettingsStore` is the only thing that writes `settings.json`, and every mutation
broadcasts. Nothing else caches the document except by subscribing to that broadcast.

### SyncoSync

The composition layer, and the only target permitted to depend on all the others.
`SyncoGraph.make` builds the object graph. `SyncEngine` owns the listener, the advertiser,
and the long-running loops. `PeerRegistry` maps discovery and settings onto connections and
decides who dials. `ClipRouter` moves clips in both directions and enforces policy on each
one. `SyncState` is the `@Observable` view of everything, and `SyncCommands` is the only
write path the UI is given.

New cross-cutting behaviour belongs here. Do not push it down into a lower target just to
avoid an import.

### SyncoUI

SwiftUI and AppKit. Reads `SyncState`, calls `SyncCommands`. It contains no networking, no
persistence, and no policy decisions — `DirectionChoice` maps a button to a `SyncDirection`
and stops there. `Theme` holds every spacing, radius, size, colour, and font; do not write
magic numbers into views.

### SyncoApp

`NSApplication` bootstrap and lifecycle only. Four files, and it should stay that way.

---

## Swift 6 strict concurrency

`Package.swift` sets `swiftLanguageModes: [.v6]`, so strict concurrency checking is on for
every target and data races are compile errors. Work with it, not around it.

- **Every public type is `Sendable`.** Value types get it by conformance; reference types
  either become actors or are `@MainActor`.
- **Mutable state lives in an actor.** `SettingsStore`, `PeerSession`, `ClipRouter`,
  `TransferManager`, `SuppressionWindow`, `BonjourBrowser`, and the registries are all
  actors. If you need shared mutable state, that is the answer.
- **UI state is `@MainActor`.** `SyncState`, `AppViewModel`, `MenuBarController`, and the
  views are main-actor isolated. `SyncState` is `@MainActor @Observable`; mutate it only
  from the main actor and let observation do the rest.
- **Never use `@unchecked Sendable`, `nonisolated(unsafe)`, or a lock to silence a
  diagnostic.** If the compiler objects, the design is wrong. The one accepted use of
  `nonisolated let` is for immutable stored properties on an actor that callers legitimately
  need synchronously, such as `PeerSession`'s configuration or `TransferManager.paths`.
- **Bridge callbacks with `AsyncStream`.** `NWBrowser`, `NWPathMonitor`, `NWListener`, and
  the pasteboard change counter all deliver on their own queues. The pattern used everywhere
  here is `AsyncStream.makeStream()`, a `@Sendable` handler that yields into the
  continuation, and an owning actor that finishes it on stop. Follow it.
- **Continuations are resumed exactly once.** `SingleResume` and `TerminationRegistry` exist
  because a network state handler can fire twice. Use them rather than hand-rolling a
  `hasResumed` flag.
- **Every long-running `Task` has an owner that cancels it.** `SyncEngine.stop()` cancels
  every loop it started; `MenuBarController.teardown()` cancels its observation loops.
  Do not spawn detached tasks that nothing can stop.

---

## Adding a new message type

A new `t` value has to land on both sides without breaking the side that does not have it
yet. The protocol is built for this: `ControlMessage` decodes an unrecognised `t` into
`.unknown(type:)` on macOS and `UnknownMessage` on Android, and both sides ignore it rather
than closing the connection. That forward-compatibility hinge is load-bearing — do not
"tighten" it into an error.

**Order of work:**

**1. Specify it first.** Add the message to §7 of `PROTOCOL.md` in *both* repositories,
identically: the `t` string, every JSON key, field types, when it is sent, and what a
receiver does with it. If it introduces a limit or a timeout, add it to §10. Both files must
stay byte-for-byte identical.

**2. macOS: define the type.**

- `Sources/SyncoCore/Messages/ControlMessageType.swift` — add the case. The raw value *is*
  the wire `t` string. Decide whether it belongs in `isPlaintextHandshake`; anything sent
  after the session is established does not.
- `Sources/SyncoCore/Messages/<Name>Message.swift` — a new file with one
  `public struct <Name>Message: Codable, Hashable, Sendable`. Write `CodingKeys` explicitly
  with the exact wire keys, even when they happen to match the Swift property names.
  Optional fields are `Optional`, so a peer that omits them still decodes.
- `Sources/SyncoCore/Messages/ControlMessage.swift` — add the case in four places: the enum,
  `typeIdentifier`, `encodableBody`, and the `init(from:)` switch. The compiler will find
  three of them; the fourth is the encoder.

**3. macOS: handle it.** Transport-level messages (anything about the connection itself) are
handled in `Sources/SyncoTransport/PeerSession+ReceiveLoop.swift`. Sync-level messages go to
`Sources/SyncoSync/ClipRouter+Inbound.swift` or a sibling. Choose by which target owns the
state the message affects; do not reach across a target boundary to handle it.

**4. Android: mirror it.**

- `core/protocol/src/main/kotlin/app/synco/protocol/message/MessageType.kt` — add the
  constant *and* add it to the `KNOWN` set. A type missing from `KNOWN` decodes as
  `UnknownMessage` no matter what else you write.
- `core/protocol/.../message/<Name>.kt` — a `@Serializable @SerialName(MessageType.X)`
  data class implementing `ControlMessage`, with `@SerialName` on every property whose wire
  key differs from the Kotlin name. `SyncoJson` is configured with
  `classDiscriminator = "t"`, `ignoreUnknownKeys = true`, `explicitNulls = false`, and
  `encodeDefaults = true` — check your defaults against that, because a Kotlin default is
  encoded but a Swift `Optional` nil is omitted.
- Handle it in `core/transport` or `sync`, matching the macOS placement.

**5. Test the wire format on both sides.** On macOS, add the key-set assertion to
`Tests/SyncoCoreTests/ControlMessageWireFormatTests.swift` and a fixture to
`ControlMessageFixtures.swift`. That test asserts the exact set of JSON keys a message
produces, which is what catches a typo that would otherwise only fail against a real phone.
Add the equivalent Kotlin test.

**6. Ship the receiver first.** Release the side that *ignores* the message before the side
that sends it, so an un-upgraded peer is never the one that has to cope.

### Changing an existing message

Adding an optional field is compatible in both directions: Swift omits a nil `Optional`,
Kotlin's `ignoreUnknownKeys` tolerates a field it does not know. Renaming a key, changing a
type, or making an optional field required is a breaking change and needs a protocol version
bump in §1 and §2, which means every device has to update. Do not do it casually.

### Cross-repository test vectors

`Tests/SyncoCryptoTests/SharedHandshakeVectors.swift` and
`Tests/SyncoCoreTests/SharedClipHashVectorTests.swift` hold hard-coded hex values — derived
keys, confirmation tags, canonical clip digests — that exist with identical values in the
Android repository. They are the cheapest possible proof that the two implementations agree
without running both devices.

If you change the key schedule, the canonical hash, or anything else those vectors cover,
update both repositories in the same change. A vector that only one side asserts is worse
than no vector at all.

---

## Tests

```sh
swift test
```

Four test targets: `SyncoCoreTests`, `SyncoCryptoTests`, `SyncoTransportTests`,
`SyncoSyncTests`. XCTest, no third-party dependencies, no mocking framework — fakes are
plain types conforming to the same protocols the production code depends on
(`FakeClipboard`, `FakeClipTransport`, `LoopbackConnectionPair`, `FixedPairingApproval`).
When you add a seam, add the fake next to the tests that need it.

Everything below `SyncoSync` should be testable without a socket, without a pasteboard, and
without a real network. If a change makes that impossible, the dependency is pointing the
wrong way.

`SyncoUI` and `SyncoApp` have no test targets. Keep logic out of them so this stays honest.

---

## Build files

`Package.swift` is off limits in ordinary changes. If a change genuinely needs a new target,
a new dependency edge, or a resource bundle, say so in the pull request and let it be applied
deliberately rather than folding it into a feature commit. The same goes for
`Resources/Info.plist` and `Resources/Synco.entitlements`: a new plist key or entitlement
changes what macOS grants the app, and that deserves its own review.

Anything touching discovery, permissions, or the login item has to be verified from a real
bundle:

```sh
./Scripts/package-app.sh
open dist/Synco.app
```

`swift build` proves it compiles. It does not prove it works.
